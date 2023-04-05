# frozen_string_literal: true

class Suma::Mobility::LimeVendorAdapter
  include Suma::Mobility::VendorAdapter

  def begin_trip(_trip)
    resp = Suma::Lime.start_trip
    return BeginTripResult.new(raw_result: resp)
  end

  def end_trip(trip)
    resp = Suma::Lime.complete_trip
    duration = resp.fetch("duration_seconds") / 60.0
    return EndTripResult.new(
      cost_cents: trip.vendor_service_rate.calculate_total(duration).cents.to_i,
      cost_currency: "USD",
      end_time: resp.fetch("completed_at"),
      duration_minutes: duration.ceil,
    )
  end
end
