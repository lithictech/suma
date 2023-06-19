# frozen_string_literal: true

require "amigo/job"

class Suma::Async::OfferingBeginFulfillment
  extend Amigo::Job

  def perform(offering_id)
    offering = self.lookup_model(Suma::Commerce::Offering, offering_id)
    offering.begin_order_fulfillment(now: Time.now)
  end
end
