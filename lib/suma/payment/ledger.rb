# frozen_string_literal: true

require "suma/payment"

class Suma::Payment::Ledger < Suma::Postgres::Model(:payment_ledgers)
  plugin :timestamps

  many_to_one :account, class: "Suma::Payment::Account"
  many_to_many :vendor_service_categories,
               class: "Suma::Vendor::ServiceCategory",
               join_table: :vendor_service_categories_payment_ledgers,
               left_key: :ledger_id,
               right_key: :category_id
  one_to_many :originated_book_transactions, class: "Suma::Payment::BookTransaction", key: :originating_ledger_id
  one_to_many :received_book_transactions, class: "Suma::Payment::BookTransaction", key: :receiving_ledger_id
  one_to_many :combined_book_transactions, class: "Suma::Payment::BookTransaction", readonly: true do |_ds|
    Suma::Payment::BookTransaction.
      where(Sequel[originating_ledger_id: id] | Sequel[receiving_ledger_id: id]).
      order(Sequel.desc(:apply_at), Sequel.desc(:id))
  end

  def balance
    credits = self.received_book_transactions.sum(Money.new(0), &:amount)
    debits = self.originated_book_transactions.sum(Money.new(0), &:amount)
    return credits - debits
  end

  # Return true if this ledger can be used to purchase the given service.
  # This is done by comparing the vendor service categories on each.
  # If any of the VSCs for the service appear in ledger's VSC graph
  # (all its VSCs and descendants), we say the ledger can be used
  # to pay for the service
  # (whether the ledger has balance is checked separately).
  #
  # For example, given the VSC tree:
  # food -> grocery -> organic
  #                 -> packaged
  #      -> restaurant
  #
  # If a ledger has "food" assigned to it,
  # the VSC graph includes all of the above nodes.
  # any vendor services with these categories (grocery, packaged, etc)
  # can be purchased by this ledger.
  #
  # If the ledger had 'organic' assigned,
  # only vendor services with 'organic' assigned could be used.
  #
  # Note that ledgers and services can have multiple service categories.
  def can_be_used_to_purchase?(vendor_service)
    match = self.category_used_to_purchase(vendor_service)
    return !match.nil?
  end

  # See can_be_used_to_purchase?. Returns the first matching category
  # which qualifies this ledger to pay for the vendor service.
  # We may need to refind this search algorithm in the future
  # if we find it doesn't select the right category.
  def category_used_to_purchase(vendor_service)
    service_cat_ids = vendor_service.categories.map(&:id)
    return self.vendor_service_categories.find do |c|
      chain_ids = c.tsort.map(&:id)
      !(service_cat_ids & chain_ids).empty?
    end
  end
end
