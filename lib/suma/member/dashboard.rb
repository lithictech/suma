# frozen_string_literal: true

require "suma/member"
require "suma/payment/ledgers_view"

class Suma::Member::Dashboard
  def initialize(member, at:)
    @member = member
    @at = at
  end

  def program_enrollments
    # TODO: I think we can remove the vendor_services/offerings and just return this?
    return @program_enrollments ||= @member.program_enrollments_dataset.active(as_of: @at).all
  end
end
