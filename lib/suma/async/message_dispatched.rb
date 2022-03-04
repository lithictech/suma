# frozen_string_literal: true

require "amigo/job"

class Suma::Async::MessageDispatched
  extend Amigo::Job

  on "suma.message.delivery.dispatched"

  def _perform(event)
    delivery = self.lookup_model(Suma::Message::Delivery, event)
    Suma::Idempotency.once_ever.under_key("message-dispatched-#{delivery.id}") do
      delivery.send!
    end
  end

  Amigo.register_job(self)
end
