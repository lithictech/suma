# frozen_string_literal: true

require "suma/member"
require "suma/payment/ledgers_view"

class Suma::Member::Dashboard
  def initialize(member, at:)
    @member = member
    @at = at
  end

  def lifetime_savings
    return @member.charges.sum(Money.new(0), &:discount_amount)
  end

  def next_offerings(limit: 2) = self.offerings.take(limit)

  def offerings
    return @offerings ||= Suma::Commerce::Offering.
        available_at(@at).
        eligible_to(@member).
        order { upper(period) }.
        all
  end

  def vendor_services_dataset
    return Suma::Vendor::Service.
        available_at(@at).
        eligible_to(@member)
  end

  def vendor_services
    return @vendor_services ||= self.vendor_services_dataset.order { upper(period) }.all
  end

  def mobility_available?
    if @mobility_available.nil?
      vehicles = Suma::Mobility::Vehicle.where(vendor_service: self.vendor_services_dataset)
      @mobility_available = !vehicles.empty?
    end
    return @mobility_available
  end

  def vendible_groupings
    return @vendible_groupings ||= Suma::Vendible.groupings(self.offerings + self.vendor_services)
  end
end
