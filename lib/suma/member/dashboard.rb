# frozen_string_literal: true

require "suma/member"
require "suma/payment/ledgers_view"

class Suma::Member::Dashboard
  def initialize(member)
    @member = member
  end

  def payment_account_balance
    pa = @member.payment_account
    return Money.new(0) if pa.nil?
    return pa.total_balance
  end

  def lifetime_savings
    return @member.charges.sum(Money.new(0), &:discount_amount)
  end

  def ledger_lines
    pa = @member.payment_account
    return [] if pa.nil?
    return Suma::Payment::LedgersView.new(pa.ledgers).recent_lines
  end

  def offerings
    return Suma::Commerce::Offering.
        available_at(Time.now).
        eligible_to(@member).
        order { upper(period) }.
        first(2)
  end

  def mobility_available?
    vendor_service = Suma::Vendor::Service.dataset.mobility.eligible_to(@member)
    vehicles = Suma::Mobility::Vehicle.where(vendor_service:)
    return !vehicles.empty?
  end
end
