# frozen_string_literal: true

require "suma/postgres/model"
require "suma/has_activity_audit"

class Suma::Payment::Trigger < Suma::Postgres::Model(:payment_triggers)
  include Suma::Postgres::HybridSearch
  include Suma::AdminLinked
  include Suma::HasActivityAudit

  plugin :hybrid_search
  plugin :timestamps
  plugin :association_pks
  plugin :tstzrange_fields, :active_during
  plugin :translated_text, :memo, Suma::TranslatedText
  plugin :translated_text, :receiving_ledger_contribution_text, Suma::TranslatedText

  many_to_one :originating_ledger, class: "Suma::Payment::Ledger"

  many_to_many :programs,
               class: "Suma::Program",
               join_table: :programs_payment_triggers,
               left_key: :trigger_id,
               order: order_desc
  include Suma::Program::Has

  one_to_many :executions, class: "Suma::Payment::Trigger::Execution", order: order_desc

  dataset_module do
    # Limit dataset to rows where +t+ is in +active_during+.
    def active_at(t)
      return self.where(Sequel.pg_range(:active_during).contains(Sequel.cast(t, :timestamptz)))
    end
  end

  # Gather a series of triggers applying to a payment account
  # so they can be used multiple times with different amounts.
  #
  # @param [Suma::Payment::Account] account
  # @param [Time] active_as_of
  # @param [Sequel::Dataset] dataset If given, the query can be filtered to just this dataset.
  #   Useful if wanting to limit the query to triggers for a set of certain programs only.
  # @return [Collection]
  def self.gather(account, active_as_of:, dataset: self.dataset)
    triggers = dataset.active_at(active_as_of).eligible_to(account.member, as_of: active_as_of).all
    return Collection.new(account:, triggers:)
  end

  # Return a new instance which sums the match_multiplier, but cannot be saved.
  # This is helpful to calculate the payer/match fraction for a set of triggers.
  def self.summed(triggers)
    r = self.new(match_multiplier: 0)
    triggers.each { |t| r.match_multiplier += t.match_multiplier }
    r.freeze
    return r
  end

  class Collection < Suma::TypedStruct
    attr_reader :account, :triggers

    # Figure out what transactions are going to be created based on a funding transaction
    # of the given +amount+ to the +account+ (ie, if I pay in cash, what subsidy do I get).
    # @param context [Suma::Payment::CalculationContext]
    # @param [Money] amount The amount of cash potentially being put in.
    # @param [Money] up_to The max amount of the charge. When calculating potential contributions,
    #   the amount may be the hypothetical cash contribution, which could be $0;
    #   so 'up to' defines the maximum potential subsidy, which is used when the trigger acts as a credit.
    # @return [Plan]
    def funding_plan(context, amount:, up_to:)
      steps = self.triggers.map { |t| t.funding_plan(context, self.account, amount:, up_to:) }
      return Plan.new(steps:)
    end

    # Return the triggers which can potentially be used for the purchase of the given item
    # with vendor service categories (look at the category hierarchy of the trigger's originating ledger).
    # Note that this should only be used for predictive/suggestive purposes,
    # since it does NOT take into account amounts on the actual ledger.
    #
    # That is, it is possible to say "we will subsidize this service 20%",
    # but this method should NOT be used to calculate the actual subsidy (use charge contributions for that).
    #
    # Note that the sum of all match multipliers can be used to calculate a total subsidy match.
    # @param has_vnd_svc [Suma::Vendor::HasServiceCategories]
    # @param summed [true,false] If true, return an array of a single trigger.
    #   See +Suma::Payment::Trigger.summed+. This is here for convenience.
    # @return [Array<Suma::Payment::Trigger>]
    def potentially_contributing_to(has_vnd_svc, summed: false)
      valid = self.triggers.select do |tr|
        tr.originating_ledger.can_be_used_to_purchase?(has_vnd_svc)
      end
      return [Suma::Payment::Trigger.summed(valid)] if summed
      return valid
    end
  end

  class Plan < Suma::TypedStruct
    # @return [Array<Suma::Payment::Trigger::PlanStep>]
    attr_accessor :steps

    # Execute this funding plan by creating book transactions for each step.
    # Only steps with a receiving ledger including in +ledgers+ are executed;
    # this is because a funding plan may have many triggers unrelated to
    # what is actually being purchased.
    # @return [Array<Suma::Payment::Trigger::Execution>]
    def execute(ledgers:, at:)
      led_ids = ledgers.to_set(&:id)
      executions = self.steps.filter_map do |step|
        next unless led_ids.include?(step.receiving_ledger.id)
        step.trigger.execute(apply_at: at, amount: step.amount, receiving_ledger: step.receiving_ledger)
      end
      return executions
    end
  end

  class PlanStep < Suma::TypedStruct
    # @return [Suma::Payment::Ledger]
    attr_accessor :receiving_ledger

    # @return [Money]
    attr_accessor :amount

    # @return [Time]
    attr_accessor :apply_at

    # @return [Suma::Payment::Trigger]
    attr_accessor :trigger
  end

  # What fraction is the customer paying? Matching 1-1 is 0.5,
  # matching $3 for every $1 spent is 0.25,
  # matching $0.50 for every $1 spent is
  def payer_fraction = (1.0 / (self.match_multiplier + 1))

  def payer_fraction=(v)
    # payer_fraction is `pf = 1 / (mm + 1)`
    # solve instead for mm (algebra 101 but reminders are nice):
    #   pf * (mm + 1) = 1
    #   mm + 1 = 1 / pf
    #   mm = (1 / pf) - 1
    self.match_multiplier = (1.0 / v) - 1
  end

  # Inverse of payer_fraction; matching $3 for every $1 spent is 0.75, etc.
  def match_fraction = 1 - self.payer_fraction

  def match_fraction=(v)
    self.payer_fraction = (1 - v)
  end

  # Figure out how much to contribute for the cash amount.
  # There are a number of interactions to consider; read the code comments for details.
  #
  # @param context [Suma::Payment::CalculationContext]
  # @param [Suma::Payment::Account] account
  # @param [Money] amount
  # @param [Money] up_to
  # @return [PlanStep]
  def funding_plan(context, account, amount:, up_to:)
    receiving = self.ensure_receiving_ledger(account)
    # The basic trigger behavior is to match a certain cash amount using the match_multiplier.
    # But there are other fields that contribute:
    # - If there is a nonzero maximum_cumulative_subsidy_cents,
    #   we never want to add an amount more than this.
    # - If act_as_credit is true, we ignore match_multiplier and cover the entire amount
    #   (up to the max subsidy, if nonzero).
    # - If unmatched_amount_cents is nonzero, we want to apply the above algorithms but *only* to the part
    #   of the amount greater than unmatched_amount_cents.
    #   - That is, if we subsidize at 0.5 at amounts above $1 with an amount of $2,
    #     we'd subsidize $0.50.
    #   - If we use act_as_credit for amounts above $1 with an amount of $1,
    #     we'd subsidize $1 (ie this could be used to provide a $10 customer cash cost to products of different prices
    #     within an offering, like the holiday special often does).
    subsidy_cents = _calculate_subsidy_cents(amount:, up_to:)
    subsidy = Money.new(
      Money.new(subsidy_cents, amount.currency).round_to_nearest_cash_value,
      amount.currency,
    )
    if self.maximum_cumulative_subsidy_cents.positive?
      max_subsidy_cents = self.maximum_cumulative_subsidy_cents
      cents_received_already = context.cached_get("trigger-funded-amt-from-#{self.id}-to-#{receiving.id}") do
        Suma::Payment::Trigger::Execution.where(trigger: self).
          join(
            Suma::Payment::BookTransaction.where(receiving_ledger: receiving),
            {id: :book_transaction_id},
          ).sum(:amount_cents)
      end
      max_subsidy_cents -= cents_received_already if cents_received_already
      max_subsidy = Money.new(max_subsidy_cents, subsidy.currency)
      subsidy = [subsidy, max_subsidy].min
    end
    return PlanStep.new(
      receiving_ledger: receiving,
      amount: subsidy,
      apply_at: context.apply_at,
      trigger: self,
    )
  end

  private def _calculate_subsidy_cents(amount:, up_to:, skip_subsidy_min_check: false)
    if !skip_subsidy_min_check && self.unmatched_amount_cents.positive?
      return 0 if amount.cents < self.unmatched_amount_cents
      min = Money.new(self.unmatched_amount_cents, amount.currency)
      return self._calculate_subsidy_cents(amount: amount - min, up_to: up_to - min, skip_subsidy_min_check: true)
    end
    # act_as_credit with no max covers the ENTIRE cost, ALWAYS (there is no max subsidy).
    return up_to.cents if self.act_as_credit && self.maximum_cumulative_subsidy_cents.zero?

    # act_as_credit should put as much as possible towards the total;
    # note that this will still be limited if max_subsidy is set.
    return [up_to.cents, self.maximum_cumulative_subsidy_cents].min if self.act_as_credit

    # The subsidized amount should be based on the match multiplier.
    return amount.cents * self.match_multiplier
  end

  def ensure_receiving_ledger(account)
    ledger = account.ledgers.find { |led| led.name == self.receiving_ledger_name }
    return ledger if ledger
    ledger = account.add_ledger(
      currency: Suma.default_currency,
      name: self.receiving_ledger_name,
      contribution_text: self.receiving_ledger_contribution_text,
    )
    self.originating_ledger.vendor_service_categories.each do |vsc|
      ledger.add_vendor_service_category(vsc)
    end
    return ledger
  end

  # @return [Suma::Payment::Trigger::Execution]
  def execute(apply_at:, amount:, receiving_ledger:, **)
    book_transaction = Suma::Payment::BookTransaction.create(
      apply_at:,
      amount:,
      receiving_ledger:,
      originating_ledger: self.originating_ledger,
      memo: self.memo,
      **,
    )
    return Suma::Payment::Trigger::Execution.create(book_transaction:, trigger: self)
  end

  # Modify this instance so +active_during_end+ is +interval+ after +active_during_begin+.
  # Create new trigger instances with the same values, but each one is +interval+ after the last.
  # The last trigger has the same +active_during_end+ of the original instance.
  # @param unit [Symbol] Must be an active support duration, like :week, :day, :month, etc.
  # @param amount [Integer] Number of units in duration each resulting trigger is.
  # @return [Array<Suma::Payment::Trigger>]
  def subdivide(unit:, amount:)
    interval = amount.send(unit)
    created = [self]
    return created if self.active_during_end <= (self.active_during_begin + interval)
    unit_lbl = amount == 1 ? unit.to_s : unit.to_s.pluralize
    self.db.transaction do
      original_end = self.active_during_end
      original_label = self.label
      self.active_during_end = self.active_during_begin + interval
      first_lbl_duration = amount == 1 ? "1" : "1-#{amount}"
      self.label = "#{self.label} (#{unit_lbl} #{first_lbl_duration})"
      self.save_changes
      loop do
        last_instance = created.last
        if last_instance.active_during_end >= original_end
          last_instance.active_during_end = original_end
          break
        end
        tvals = self.values.dup
        tvals.delete(:id)
        instance = self.class.new(tvals)
        interval_lbl = if amount == 1
                         (created.count + 1).to_s
                       else
                         interval_start = created.count * amount
                         "#{interval_start + 1}-#{interval_start + amount}"
                        end
        instance.label = "#{original_label} (#{unit_lbl} #{interval_lbl})"
        instance.active_during_begin = last_instance.active_during_end
        instance.active_during_end = instance.active_during_begin + interval
        instance.save_changes
        created << instance
      end
      return created
    end
  end

  def rel_admin_link = "/payment-trigger/#{self.id}"

  def hybrid_search_fields
    return [
      :label,
      :active_during_begin,
      :active_during_end,
      :memo,
      :receiving_ledger_name,
      ["Originating ledger", self.originating_ledger.admin_label],
    ]
  end

  # @!attribute label
  # Admin-facing name for the automation.
  # @return [String]

  # @!attribute active_during
  # @return [Range]

  # @!attribute match_multiplier
  # Amount to multiply a transaction amount against, to get the trigger amount.
  # 1 would be a 1-to-1 match, 3.8 would be '$19 for $5 cash', etc.
  # @return [Decimal]

  # @!attribute maximum_cumulative_subsidy_cents
  # How much subsidy should we allow the ledger to get up to?
  # For example, with a 1-to-1 match, and a value of 2000,
  # we'd match only the first $20 of a charge.
end

# Table: payment_triggers
# --------------------------------------------------------------------------------------------------------------------------------------
# Columns:
#  id                                    | integer                  | PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY
#  created_at                            | timestamp with time zone | NOT NULL DEFAULT now()
#  updated_at                            | timestamp with time zone |
#  label                                 | text                     | NOT NULL
#  active_during                         | tstzrange                | NOT NULL
#  match_multiplier                      | numeric                  | NOT NULL
#  maximum_cumulative_subsidy_cents      | integer                  | NOT NULL
#  memo_id                               | integer                  | NOT NULL
#  originating_ledger_id                 | integer                  | NOT NULL
#  receiving_ledger_name                 | text                     | NOT NULL
#  receiving_ledger_contribution_text_id | integer                  | NOT NULL
#  search_content                        | text                     |
#  search_embedding                      | vector(384)              |
#  search_hash                           | text                     |
#  act_as_credit                         | boolean                  | NOT NULL DEFAULT false
#  unmatched_amount_cents                | integer                  | NOT NULL DEFAULT 0
# Indexes:
#  payment_triggers_pkey                          | PRIMARY KEY btree (id)
#  payment_triggers_search_content_trigram_index  | gist (search_content)
#  payment_triggers_search_content_tsvector_index | gin (to_tsvector('english'::regconfig, search_content))
# Foreign key constraints:
#  payment_triggers_memo_id_fkey                               | (memo_id) REFERENCES translated_texts(id)
#  payment_triggers_originating_ledger_id_fkey                 | (originating_ledger_id) REFERENCES payment_ledgers(id)
#  payment_triggers_receiving_ledger_contribution_text_id_fkey | (receiving_ledger_contribution_text_id) REFERENCES translated_texts(id)
# Referenced By:
#  payment_trigger_executions | payment_trigger_executions_trigger_id_fkey | (trigger_id) REFERENCES payment_triggers(id)
#  programs_payment_triggers  | programs_payment_triggers_trigger_id_fkey  | (trigger_id) REFERENCES payment_triggers(id)
# --------------------------------------------------------------------------------------------------------------------------------------
