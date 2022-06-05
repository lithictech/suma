# frozen_string_literal: true

require "suma/payment"

class Suma::Payment::BookTransaction < Suma::Postgres::Model(:payment_book_transactions)
  plugin :timestamps
  plugin :money_fields, :amount

  many_to_one :originating_ledger, class: "Suma::Payment::Ledger"
  many_to_one :receiving_ledger, class: "Suma::Payment::Ledger"
  many_to_one :associated_vendor_service_category, class: "Suma::Vendor::ServiceCategory"

  def initialize(*)
    super
    self.opaque_id ||= Suma::Secureid.new_opaque_id("bx")
  end

  # Return a copy of the receiver, but with id removed, and amount set to be positive or negative
  # based on whether the receiver is the originating or receiving ledger.
  # This is used in places we need to represent book transactions
  # as ledger line items which have a directionality to them,
  # and we do not have a ledger as the time to determine directionality.
  #
  # The returned instance is frozen so cannot be saved/updated.
  def directed(relative_to_ledger)
    dup = self.values.dup
    case relative_to_ledger
      when self.originating_ledger
        dup[:amount_cents] *= -1
      when self.receiving_ledger
        nil
      else
        raise ArgumentError, "#{relative_to_ledger.inspect} is not associated with #{self.inspect}"
    end
    id = dup.delete(:id)
    inst = self.class.new(dup)
    inst.values[:_directed] = true
    inst.values[:id] = id
    inst.freeze
    return inst
  end

  # Return true if the received is an output of +directed+.
  def directed?
    return self.values.fetch(:_directed, false)
  end
end
