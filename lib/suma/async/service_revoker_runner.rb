# frozen_string_literal: true

require "amigo/job"

# Run the service revoker on the originating ledger
# any time a book transaction is created.
class Suma::Async::ServiceRevokerRunner
  extend Amigo::Job

  on "suma.payment.booktransaction.created"

  def _perform(event)
    bx = self.lookup_model(Suma::Payment::BookTransaction, event)
    Suma::Program::ServiceRevoker.run_for(bx.originating_ledger)
  end
end
