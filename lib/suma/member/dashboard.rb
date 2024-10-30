# frozen_string_literal: true

require "suma/member"
require "suma/payment/ledgers_view"

class Suma::Member::Dashboard
  def initialize(member, at:)
    @member = member
    @at = at
  end

  def offerings
    return @offerings ||= Suma::Commerce::Offering.
        available_at(@at).
        eligible_to(@member, as_of: @at).
        order { upper(period) }.
        all
  end

  def vendor_services_dataset
    return Suma::Vendor::Service.
        available_at(@at).
        eligible_to(@member, as_of: @at)
  end

  def vendor_services
    return @vendor_services ||= self.vendor_services_dataset.order { upper(period) }.all
  end

  def programs
    # TODO: Only unique programs
    #  and I think we can remove the vendor_services/offerings and just serve them from programs
    return @programs ||= @member.program_enrollments_dataset.active(as_of: @at).all.map(&:program)
  end
end
