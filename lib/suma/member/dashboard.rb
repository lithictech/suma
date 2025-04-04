# frozen_string_literal: true

require "suma/member"
require "suma/payment/ledgers_view"

class Suma::Member::Dashboard
  def initialize(member, at:)
    @member = member
    @at = at
  end

  def cash_balance
    # The dashboard is the first thing people see after signing up,
    # and it's possible workers are slow. This would cause an error.
    # So make sure they have a ledger at this point.
    # We don't want to create the ledger for every member,
    # since it would be an issue for tests and all code that never
    # has to worry about a ledger.
    Suma::Payment.ensure_cash_ledger(@member)
    return @member.payment_account!.cash_ledger!.balance
  end

  def program_enrollments
    # Similar to the cash ledger, make sure every member gets a member role by default.
    Suma::Role.cache.member.ensure!(@member)
    return @program_enrollments ||= @member.combined_program_enrollments_dataset.active(as_of: @at).
        all.sort_by { |pe| pe.program.ordinal }
  end
end
