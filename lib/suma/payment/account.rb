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
  one_to_many :originated_funding_transactions, key: :originating_payment_account_id,
                                                class: "Suma::Payment::FundingTransaction", read_only: true
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

  def mobility_ledger!
    return self.mobility_ledger if self.mobility_ledger
    raise "PaymentAccount[#{self.id}] has no mobility ledger"
  end

  # Find ledgers that have overlapping categories, and their contributions towards the charge amount.
  #
  # If +remainder_ledger+ is nil, and the balance across all relevant cannot cover the amount,
  # raise +Suma::Payment::InsufficientFunds+.
  #
  # If +remainder_ledger+ is passed, and the balance across all relevant ledgers cannot cover the amount,
  # +remainder_ledger+ must be one of the following:
  #
  # - +Suma::Payment::Ledger+ instance: the remainder will be a contribution from this ledger,
  #   sending it into the negative. NOTE: the ledger used here must be valid for the service categories;
  #   usually this means it is the cash or root ledger.
  # - +:first+: Use the first matching ledger. Usually this is the most specific ledger that can be charged
  #  ("organic vegetables" rather than "food", for example).
  # - +:last+: Use the last matching ledger. Usually this is the least specific ledger, like "food" or "cash".
  # - +:ignore+: The contributions will be returned as-is, and not cover the full amount.
  #   This can be useful to see how much of an amount can be covered by the current ledgers,
  #   assuming the remainder will be handled later (like during order checkout).
  # - +:return+: Return an additional ChargeContribution with a nil ledger and category.
  #
  # @param has_vnd_svc_categories [Suma::Vendor::HasServiceCategories]
  # @param amount [Money]
  # @param calculation_context [Suma::Payment::CalculationContext]
  # @param now [Time]
  # @param remainder_ledger [Suma::Payment::Ledger, :first, :last, :ignore] See above.
  # @param exclude_up [Enumerable<Suma::Vendor::ServiceCategory>] Categories of ledgers to exclude.
  #   Specifically, the categories here will 'walk up' the parents,
  #   and ledgers that are assigned to only a subset of these categories
  #   cannot be used for charging. The main purpose of this argument is to find out how much of a product/service
  #   can be charged to 'sub ledgers' rather than the fall back/cash ledger.
  #   For example, given:
  #   - categories a, and x->y->z
  #   - ledgerAY with (a, y), ledgerY with (y)
  #   Excluding y or z would exclude ledgerY (because ledgerA still has category a).
  #   Excluding x would not exclude anything.
  # @return [Array<Suma::Payment::ChargeContribution]
  def find_chargeable_ledgers(has_vnd_svc_categories, amount, calculation_context:, now:,
    remainder_ledger: nil, exclude_up: nil)

    raise ArgumentError, "amount cannot be negative, got #{amount.format}" if amount.negative?
    raise Suma::InvalidPrecondition, "#{self.inspect} has no ledgers" if self.ledgers.empty?
    contributions = []
    exclusions = exclude_up.present? && exclude_up.map(&:hierarchy_up).flatten.map(&:id).to_set
    self.ledgers.each do |led|
      next if exclusions && led.vendor_service_categories.map(&:id).to_set.subset?(exclusions)
      cat = led.category_used_to_purchase(has_vnd_svc_categories)
      if cat
        contributions << Suma::Payment::ChargeContribution.new(ledger: led, apply_at: now, amount: 0, category: cat)
      end
    end
    contributions.sort_by! { |c| [-c.category.hierarchy_depth, c.ledger.id] }
    remainder = amount
    result = []
    contributions.each do |contrib|
      ledger_balance = calculation_context.balance(contrib.ledger)
      amount = [ledger_balance, 0].max
      amount = [amount, remainder].min
      contrib.amount = amount
      result << contrib
      remainder -= amount
      break if remainder.zero?
    end
    # We've covered the full cost
    return result if remainder.zero?
    raise "how did we get a negative remainder? #{remainder}" if remainder.negative?

    case remainder_ledger
      when nil
        raise Suma::Payment::InsufficientFunds
      when :ignore
        return result
      when :return
        result << Suma::Payment::ChargeContribution.new(ledger: nil, apply_at: now, amount: remainder, category: nil)
        return result
      when Symbol
        raise Suma::InvalidPrecondition, "No ledgers for charge contributions could be found" if contributions.empty?
        contributions.send(remainder_ledger).amount += remainder
        return result
      else
        contrib_for_remainder = contributions.find { |c| c.ledger === remainder_ledger }
        raise Suma::InvalidPrecondition, "Remainder ledger #{remainder_ledger.id} not valid for charge contributions" if
          contrib_for_remainder.nil?
        contrib_for_remainder.amount += remainder
        return result
    end
  end

  def debit_contributions(contributions, memo:)
    xactions = contributions.map do |c|
      Suma::Payment::BookTransaction.create(
        apply_at: c.apply_at,
        amount: c.amount,
        originating_ledger: c.ledger,
        receiving_ledger: Suma::Payment::Account.lookup_platform_vendor_service_category_ledger(c.category),
        associated_vendor_service_category: c.category,
        memo:,
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
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
