# frozen_string_literal: true

require "amigo/job"

class Suma::Async::MemberDefaultRelations
  extend Amigo::Job

  on "suma.member.created"

  def _perform(event)
    c = self.lookup_model(Suma::Member, event)
    Suma::Payment.ensure_cash_ledger(c)
    Suma::Role.cache.member.ensure!(c)
  end
end
j
