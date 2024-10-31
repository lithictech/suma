# frozen_string_literal: true

require "suma/member"
require "suma/payment/ledgers_view"

class Suma::Member::Dashboard
  def initialize(member, at:)
    @member = member
    @at = at
  end

  def program_enrollments
    return @program_enrollments ||= @member.program_enrollments_dataset.active(as_of: @at).all
  end
end
