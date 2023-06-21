# frozen_string_literal: true

require "amigo/job"

require "suma/async/offering_begin_fulfillment"

class Suma::Async::OfferingScheduleFulfillment
  extend Amigo::Job

  on "suma.commerce.offering.*"

  def _perform(e)
    offering = self.lookup_model(Suma::Commerce::Offering, e)
    begin_at = offering.begin_fulfillment_at
    return if begin_at.nil?
    if e.name == "suma.commerce.offering.created"
      Suma::Async::OfferingBeginFulfillment.perform_at(begin_at, offering.id)
      return
    end
    case e.payload[1]
      when changed(:begin_fulfillment_at)
        Suma::Async::OfferingBeginFulfillment.perform_at(begin_at, offering.id)
    end
  end
end
