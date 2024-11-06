# frozen_string_literal: true

require "suma/member"
require "suma/payment/ledgers_view"

class Suma::Member::Dashboard
  def initialize(member, at:)
    @member = member
    @at = at
  end

  def cash_balance
    return @member.payment_account!.cash_ledger!.balance
  end

  def program_enrollments
    return @program_enrollments ||= @member.combined_program_enrollments_dataset.active(as_of: @at).all
  end
end
