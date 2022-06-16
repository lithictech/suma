# frozen_string_literal: true

require "amigo/job"

class Suma::Async::EnsureDefaultMemberLedgersOnCreate
  extend Amigo::Job

  on "suma.customer.created"

  def _perform(event)
    c = self.lookup_model(Suma::Member, event)
    Suma::Payment.ensure_cash_ledger(c)
  end

  Amigo.register_job(self)
end
