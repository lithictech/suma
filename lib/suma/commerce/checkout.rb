# frozen_string_literal: true

require "suma/commerce"
require "suma/postgres/model"

class Suma::Commerce::Checkout < Suma::Postgres::Model(:commerce_checkouts)
  CONFIRMATION_EXPOSURE_CUTOFF = 2.days

  plugin :timestamps
  plugin :soft_deletes

  many_to_one :cart, class: "Suma::Commerce::Cart"
  many_to_one :card, class: "Suma::Payment::Card"
  many_to_one :bank_account, class: "Suma::Payment::BankAccount"
  one_to_many :items, class: "Suma::Commerce::CheckoutItem"
  one_to_many :orders, class: "Suma::Commerce::Order"
  many_to_one :fulfillment_option, class: "Suma::Commerce::OfferingFulfillmentOption"

  def editable? = !self.soft_deleted? && !self.completed?
  def completed? = !self.completed_at.nil?
  def available_fulfillment_options = self.cart.offering.fulfillment_options
  def available_payment_instruments = self.cart.member.usable_payment_instruments

  def expose_for_confirmation?(t=Time.now)
    cutoff = t - CONFIRMATION_EXPOSURE_CUTOFF
    return self.created_at > cutoff
  end

  def complete(t=Time.now)
    self.completed_at = t
    return self
  end

  def payment_instrument
    return [self.bank_account, self.card].compact.first
  end

  def payment_instrument=(pi)
    case pi
      when nil
        self.bank_account = nil
        self.card = nil
      when Suma::Payment::BankAccount
        self.bank_account = pi
        self.card = nil
      when Suma::Payment::Card
        self.bank_account = nil
        self.card = pi
      else
        raise "Unhandled payment instrument: #{pi.inspect}"
    end
  end

  def undiscounted_cost = self.items.sum(Money.new(0), &:undiscounted_cost)
  def customer_cost = self.items.sum(Money.new(0), &:customer_cost)
  def savings = self.items.sum(Money.new(0), &:savings)
  def handling = Money.new(0)
  def taxable_cost = self.handling + self.customer_cost
  def tax = Money.new(0)
  def total = self.customer_cost + self.handling
end
