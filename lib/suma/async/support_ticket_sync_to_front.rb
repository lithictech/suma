# frozen_string_literal: true

class Suma::Async::SupportTicketSyncToFront
  extend Amigo::Job

  on "suma.support.ticket.created"

  def _perform(event)
    return unless Suma::Frontapp.configured?
    ticket = self.lookup_model(Suma::Support::Ticket, event)
    ticket.sync_to_front
  end
end
