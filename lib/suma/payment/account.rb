# frozen_string_literal: true

require "suma/admin_linked"
require "suma/moneyutil"
require "suma/payment"
require "suma/payment/calculation_context"
require "suma/payment/charge_contribution"

class Suma::Payment::Account < Suma::Postgres::Model(:payment_accounts)
  include Suma::AdminLinked

  plugin :timestamps

  many_to_one :member, class: "Suma::Member"
  many_to_one :vendor, class: "Suma::Vendor"
  one_to_many :originated_funding_transactions,
              key: :originating_payment_account_id,
              class: "Suma::Payment::FundingTransaction",
              read_only: true
  one_to_many :originated_payout_transactions,
              key: :originating_payment_account_id,
              class: "Suma::Payment::PayoutTransaction",
              read_only: true
  one_to_many :ledgers, class: "Suma::Payment::Ledger"
  one_to_one :cash_ledger, class: "Suma::Payment::Ledger", read_only: true do |ds|
    ds.where(vendor_service_categories: Suma::Vendor::ServiceCategory.where(slug: "cash"))
  end
  one_to_one :mobility_ledger, class: "Suma::Payment::Ledger", read_only: true do |ds|
    ds.where(vendor_service_categories: Suma::Vendor::ServiceCategory.where(slug: "mobility"))
  end
  many_through_many :all_book_transactions,
                    [
                      [:payment_ledgers, :account_id, :id],
                    ],
                    class: "Suma::Payment::BookTransaction",
                    left_primary_key: :id,
                    # This is gross, but good enough for now.
                    right_primary_key: Sequel.case(
                      {Sequel[originating_ledger_id: Sequel[:payment_ledgers][:id]] => :originating_ledger_id},
                      :receiving_ledger_id,
                    ),
                    read_only: true

  def self.lookup_platform_account
    return Suma.cached_get("platform_payment_account") do
      pa = self[is_platform_account: true]
      pa ||= self.create(is_platform_account: true)
      pa
    end
  end

  def self.lookup_platform_vendor_service_category_ledger(cat)
    return Suma.cached_get("platform_payment_ledger_for_category_#{cat.id}") do
      pa = self.lookup_platform_account
      pa.lock!
      unless (led = pa.ledgers_dataset[vendor_service_categories: cat])
        led = pa.add_ledger({currency: Suma.default_currency, name: cat.name})
        led.add_vendor_service_category(cat)
      end
      led
    end
  end

  def platform_account? = self.is_platform_account

  def rel_admin_link
    return "/payment-accounts/platform" if self.platform_account?
    return self.member&.rel_admin_link || self.vendor&.rel_admin_link || "/payment-accounts/#{self.id}"
  end

  def display_name
    return "Suma Platform" if self.platform_account?
    return self.member&.name || self.vendor&.name || "Payment Account #{self.id}"
  end

  def total_balance
    return self.ledgers.sum(Money.new(0), &:balance)
  end

  def cash_ledger!
    return self.cash_ledger if self.cash_ledger
    raise "PaymentAccount[#{self.id}] has no cash ledger"
  end

  def ensure_cash_ledger
    self.db.transaction do
      self.lock!
      ledger = self.cash_ledger
      return ledger if ledger
      ledger = self.add_ledger({currency: Suma.default_currency, name: "Cash"})
      ledger.contribution_text.update(en: "General Balance", es: "Balance general")
      ledger.add_vendor_service_category(Suma::Vendor::ServiceCategory.cash)
      self.associations.delete(:cash_ledger)
      return ledger
    end
  end

  def mobility_ledger!
    return self.mobility_ledger if self.mobility_ledger
    raise "PaymentAccount[#{self.id}] has no mobility ledger"
  end

  # Find ledgers that have overlapping categories, and their contributions towards the charge amount.
  # See +Suma::Payment::ChargeContribution::Collection+ for details about returned fields.
  #
  # @param context [Suma::Payment::CalculationContext]
  # @param has_vnd_svc_categories [Suma::Vendor::HasServiceCategories]
  # @param amount [Money]
  # @return [Suma::Payment::ChargeContribution::Collection]
  def calculate_charge_contributions(context, has_vnd_svc_categories, amount)
    raise ArgumentError, "amount cannot be negative, got #{amount.format}" if amount.negative?
    raise Suma::InvalidPrecondition, "#{self.inspect} has no cash ledger" unless (cash_ledger = self.cash_ledger)
    result = Suma::Payment::ChargeContribution::Collection.create_empty(context, cash_ledger)
    potential_contribs = []
    self.ledgers.each do |ledger|
      if (category = ledger.category_used_to_purchase(has_vnd_svc_categories))
        if ledger === cash_ledger
          result.cash.mutate_category(category)
        else
          potential_contribs << Suma::Payment::ChargeContribution.new(ledger:, apply_at: context.apply_at, category:)
        end
      end
    end
    potential_contribs.sort_by! { |c| [-c.category.hierarchy_depth, c.ledger.id] }
    remainder = amount
    (potential_contribs + [result.cash]).each do |contrib|
      ledger_balance = context.balance(contrib.ledger)
      amount = [ledger_balance, 0].max
      amount = [amount, remainder].min
      contrib.mutate_amount(amount)
      (result.rest << contrib) if contrib != result.cash
      remainder -= amount
      break if remainder.zero?
    end
    raise Suma::InvalidPostcondition, "how did we get a negative remainder? #{remainder}" if remainder.negative?
    result.remainder = remainder
    return result
  end

  # Create a +Suma::Payment::BookTransaction+ for each non-zero contribution in the collection.
  # @param [Array<Suma::Payment::ChargeContribution>] contributions
  # @param [Suma::TranslatedText] memo
  def debit_contributions(contributions, memo:)
    xactions = contributions.map do |c|
      Suma::Payment::BookTransaction.create(
        apply_at: c.apply_at,
        amount: c.amount,
        originating_ledger: c.ledger,
        receiving_ledger: Suma::Payment::Account.lookup_platform_vendor_service_category_ledger(c.category),
        associated_vendor_service_category: c.category,
        memo:,
        actor: Suma::Payment::BookTransaction.current_actor,
      )
    end
    return xactions
  end
end

# Table: payment_accounts
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Columns:
#  id                  | integer                  | PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY
#  created_at          | timestamp with time zone | NOT NULL DEFAULT now()
#  updated_at          | timestamp with time zone |
#  member_id           | integer                  |
#  vendor_id           | integer                  |
#  is_platform_account | boolean                  | NOT NULL DEFAULT false
# Indexes:
#  payment_accounts_pkey          | PRIMARY KEY btree (id)
#  one_platform_account           | UNIQUE btree (is_platform_account) WHERE is_platform_account IS TRUE
#  payment_accounts_member_id_key | UNIQUE btree (member_id)
#  payment_accounts_vendor_id_key | UNIQUE btree (vendor_id)
# Check constraints:
#  unambiguous_owner | (member_id IS NOT NULL AND vendor_id IS NULL OR member_id IS NULL AND vendor_id IS NOT NULL OR is_platform_account IS TRUE AND member_id IS NULL AND vendor_id IS NULL)
# Foreign key constraints:
#  payment_accounts_member_id_fkey | (member_id) REFERENCES members(id)
#  payment_accounts_vendor_id_fkey | (vendor_id) REFERENCES vendors(id)
# Referenced By:
#  payment_funding_transactions | payment_funding_transactions_originating_payment_account_i_fkey | (originating_payment_account_id) REFERENCES payment_accounts(id) ON DELETE RESTRICT
#  payment_ledgers              | payment_ledgers_account_id_fkey                                 | (account_id) REFERENCES payment_accounts(id)
#  payment_payout_transactions  | payment_payout_transactions_originating_payment_account_id_fkey | (originating_payment_account_id) REFERENCES payment_accounts(id) ON DELETE RESTRICT
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
