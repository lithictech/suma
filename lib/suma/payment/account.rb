# frozen_string_literal: true

require "suma/moneyutil"
require "suma/payment"

class Suma::Payment::Account < Suma::Postgres::Model(:payment_accounts)
  plugin :timestamps

  many_to_one :customer, class: "Suma::Customer"
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

  def find_chargeable_ledgers(vendor_service, amount, now:, allow_negative_balance: false)
    raise ArgumentError, "amount cannot be negative, got #{amount.format}" if amount.negative?
    raise Suma::InvalidPrecondition, "#{self.inspect} has no ledgers" if self.ledgers.empty?
    contributions = []
    self.ledgers.each do |led|
      cat = led.category_used_to_purchase(vendor_service)
      contributions << ChargeContribution.new(ledger: led, apply_at: now, amount: 0, category: cat) if cat
    end
    contributions.sort_by! { |c| [-c.category.hierarchy_depth, c.ledger.id] }
    remainder = amount
    result = []
    contributions.each do |contrib|
      amount = [contrib.ledger.balance, 0].max
      amount = [amount, remainder].min
      contrib.amount = amount
      result << contrib
      remainder -= amount
      break if remainder.zero?
    end
    return result if remainder.zero?
    raise Suma::Payment::InsufficientFunds if !allow_negative_balance && remainder.positive?
    Suma::Moneyutil.divide(remainder, contributions.size).each_with_index do |leftover, idx|
      result[idx].amount += leftover
    end
    return result
  end

  class ChargeContribution < Suma::TypedStruct
    attr_accessor :ledger, :apply_at, :amount, :category
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
