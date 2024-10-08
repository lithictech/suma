# frozen_string_literal: true

require "suma/postgres/model"

class Suma::Payment::Trigger < Suma::Postgres::Model(:payment_triggers)
  include Suma::AdminLinked

  plugin :timestamps
  plugin :tstzrange_fields, :active_during
  plugin :translated_text, :memo, Suma::TranslatedText
  plugin :translated_text, :receiving_ledger_contribution_text, Suma::TranslatedText

  many_to_one :originating_ledger, class: "Suma::Payment::Ledger"

  many_to_many :eligibility_constraints,
               class: "Suma::Eligibility::Constraint",
               join_table: :eligibility_payment_trigger_associations,
               right_key: :constraint_id,
               left_key: :trigger_id
  include Suma::Eligibility::HasConstraints

  one_to_many :executions, class: "Suma::Payment::Trigger::Execution"

  dataset_module do
    # Limit dataset to rows where +t+ is in +active_during+.
    def active_at(t)
      return self.where(Sequel.pg_range(:active_during).contains(Sequel.cast(t, :timestamptz)))
    end

    # Limit dataset to rows where 1) there are no trigger constraints, meaning everyone can use it,
    # or 2) the verified member constraints and the trigger constraints overlap.
    def eligible_to_member(member)
      constraint_ids = member.verified_eligibility_constraints.map(&:id)
      no_constraint = Sequel[:id] !~ self.db[:eligibility_payment_trigger_associations].select(:trigger_id)
      has_constraint = Sequel[id: self.db[:eligibility_payment_trigger_associations].
        where(constraint_id: constraint_ids).
        select(:trigger_id)]
      return self.where(no_constraint | has_constraint)
    end
  end

  # Gather a series of triggers applying to a payment account
  # so they can be used multiple times with different amounts.
  # @param [Suma::Payment::Account] account
  # @return [Collection]
  def self.gather(account, apply_at:)
    triggers = self.dataset.active_at(apply_at).eligible_to_member(account.member).all
    return Collection.new(account:, triggers:, apply_at:)
  end

  class Collection < Suma::TypedStruct
    attr_reader :account, :apply_at, :triggers

    # Figure out what transactions are going to be created based on a funding transaction
    # of the given +amount+ to the +account+ (ie, if I pay in cash, what subsidy do I get).
    # @param [Money] amount
    # @return [Plan]
    def funding_plan(amount)
      steps = self.triggers.map { |t| t.funding_plan(self.account, amount, apply_at: self.apply_at) }
      return Plan.new(steps:)
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
        book_transaction = Suma::Payment::BookTransaction.create(
          apply_at: at,
          amount: step.amount,
          originating_ledger: step.trigger.originating_ledger,
          receiving_ledger: step.receiving_ledger,
          memo: step.trigger.memo,
        )
        Suma::Payment::Trigger::Execution.create(book_transaction:, trigger: step.trigger)
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

  # @param [Suma::Payment::Account] account
  # @param [Money] amount
  # @return [PlanStep]
  def funding_plan(account, amount, apply_at:)
    receiving = self.ensure_receiving_ledger(account)
    subsidy = Money.new(
      Money.new(amount.cents * self.match_multiplier, amount.currency).round_to_nearest_cash_value,
      amount.currency,
    )
    if self.maximum_cumulative_subsidy_cents
      max_subsidy_cents = self.maximum_cumulative_subsidy_cents
      cents_received_already = Suma::Payment::Trigger::Execution.where(trigger: self).
        join(
          Suma::Payment::BookTransaction.where(receiving_ledger: receiving),
          {id: :book_transaction_id},
        ).sum(:amount_cents)
      max_subsidy_cents -= cents_received_already if cents_received_already
      max_subsidy = Money.new(max_subsidy_cents, subsidy.currency)
      subsidy = [subsidy, max_subsidy].min
    end
    return PlanStep.new(
      receiving_ledger: receiving,
      amount: subsidy,
      apply_at:,
      trigger: self,
    )
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

  def member_passes_constraints?(member_id, constraint_name)
    return true if constraint_name.blank?
    constraints_ds = Suma::Eligibility::Constraint.where(name: constraint_name)
    member_passes_constraints = !Suma::Member.
      where(id: member_id).
      where(verified_eligibility_constraints: constraints_ds).
      empty?
    return member_passes_constraints
  end

  def rel_admin_link = "/payment-trigger/#{self.id}"

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
# ---------------------------------------------------------------------------------------------------------------------------------------------------
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
# Indexes:
#  payment_triggers_pkey | PRIMARY KEY btree (id)
# Foreign key constraints:
#  payment_triggers_memo_id_fkey                               | (memo_id) REFERENCES translated_texts(id)
#  payment_triggers_originating_ledger_id_fkey                 | (originating_ledger_id) REFERENCES payment_ledgers(id)
#  payment_triggers_receiving_ledger_contribution_text_id_fkey | (receiving_ledger_contribution_text_id) REFERENCES translated_texts(id)
# Referenced By:
#  eligibility_payment_trigger_associations | eligibility_payment_trigger_associations_trigger_id_fkey | (trigger_id) REFERENCES payment_triggers(id)
#  payment_trigger_executions               | payment_trigger_executions_trigger_id_fkey               | (trigger_id) REFERENCES payment_triggers(id)
# ---------------------------------------------------------------------------------------------------------------------------------------------------
