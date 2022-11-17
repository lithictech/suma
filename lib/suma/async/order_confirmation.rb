# frozen_string_literal: true

require "amigo/job"
require "suma/messages/order_confirmation"

class Suma::Async::OrderConfirmation
  extend Amigo::Job

  on "suma.commerce.order.created"

  def _perform(event)
    o = self.lookup_model(Suma::Commerce::Order, event)
    return if o.checkout.cart.offering.confirmation_template.blank?
    Suma::Idempotency.once_ever.under_key("order-#{o.id}-confirmation") do
      msg = Suma::Messages::OrderConfirmation.new(o)
      o.checkout.cart.member.message_preferences!.dispatch(msg)
    end
  end

  Amigo.register_job(self)
end
