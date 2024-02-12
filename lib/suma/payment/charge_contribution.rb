# frozen_string_literal: true

require "suma/payment"

class Suma::Payment::ChargeContribution < Suma::TypedStruct
  attr_accessor :ledger, :apply_at, :amount, :category

  def _defaults
    return {amount: Money.new(0)}
  end

  # @!attribute ledger
  # Ledger for the contribution. Is nil for the 'remainder' ledger.
  # @return [Suma::Payment::Ledger]

  # @!attribute apply_at
  # @return [Time]

  # @!attribute amount
  # @return [Money]

  # @!attribute category
  # @return [Suma::Vendor::ServiceCategory]

  def debitable? = self.amount.positive? && !self.ledger.nil?

  # @return [ChargeContribution]
  def dup
    return self.class.new(
      ledger: self.ledger,
      apply_at: self.apply_at,
      amount: self.amount,
      category: self.category,
    )
  end

  class Collection < Suma::TypedStruct
    attr_accessor :cash, :remainder, :rest

    # @!attribute cash
    # The contribution from the cash ledger, using its existing balance.
    # Its amount will be 0 if other ledgers cover the full amount,
    # or its balance is 0.
    # Its category is always nil.
    # @return [Suma::Payment::ChargeContribution]

    # @!attribute remainder
    # The amount not covered by existing ledgers, that may need to be charged.
    # Its ledger is always nil (the caller can decide to do a cash charge, create an additional subsidy, etc).
    # The amount will be 0 if ledger balances cover the full amount.
    # Its category is always nil.
    # @return [Suma::Payment::ChargeContribution]

    # @!attribute rest
    # The contributions from other ledgers.
    # @return [Array<Suma::Payment::ChargeContribution>]

    def remainder? = self.remainder.amount.positive?

    # Contributions that can be charged (positive amount and have a ledger/not the remainder).
    # @return [Enumerable<Suma::Payment::ChargeContribution>]
    def debitable = self.all.select(&:debitable?)

    # @return [Array<Suma::Payment::ChargeContribution>]
    def debitable_or(category:, ledger:)
      d = self.debitable.to_a
      return d unless d.empty?
      return [Suma::Payment::ChargeContribution.new(apply_at: self.cash.apply_at, category:, ledger:)]
    end

    # @return [Enumerable<Suma::Payment::ChargeContribution>]
    def all(&)
      return to_enum(:all) unless block_given?
      yield self.cash
      self.rest.each(&)
      yield self.remainder
    end

    def self.create_empty(cash_ledger, apply_at:)
      return Suma::Payment::ChargeContribution::Collection.new(
        cash: Suma::Payment::ChargeContribution.new(
          ledger: cash_ledger, apply_at:, amount: Money.new(0), category: Suma::Vendor::ServiceCategory.cash,
        ),
        remainder: Suma::Payment::ChargeContribution.new(ledger: nil, apply_at:, amount: Money.new(0), category: nil),
        rest: [],
      )
    end

    # Merge many contribution collections together.
    # +cash+ and +remainder+ amounts are summed, while the +rest+ array
    # has a unique entry for each ledger.
    # Note that +rest+ contributions will the +category+ of one contribution;
    # consolidation is inherently lossy, so if one +rest+ ledger supports multiple categories
    # (say "food" ledger for "organic" and "local" categories) it will have only one of those categories.
    # @param [Array<Collection>] collections
    # @return [Collection]
    def self.consolidate(collections)
      raise ArgumentError, "collections cannot be empty" if collections.empty?
      result = self.new(
        cash: collections[0].cash.dup,
        remainder: collections[0].remainder.dup,
        rest: collections[0].rest.map(&:dup),
      )
      collections[1..].each do |col|
        result.cash.amount += col.cash.amount
        result.remainder.amount += col.remainder.amount
        col.rest.each do |c|
          other_contrib = result.rest.find do |r|
            r.ledger === c.ledger && r.category === c.category
          end
          if other_contrib.nil?
            result.rest << c.dup
          else
            other_contrib.amount += c.amount
          end
        end
      end
      return result
    end
  end
end
