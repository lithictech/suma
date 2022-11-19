# frozen_string_literal: true

require "suma/payment"

class Suma::Payment::ChargeContribution < Suma::TypedStruct
  attr_accessor :ledger, :apply_at, :amount, :category

  def remainder? = self.ledger.nil?
end
