# frozen_string_literal: true

class Suma::Mobility::FakeVendorAdapter
  include Suma::Mobility::VendorAdapter

  def begin_trip(_member, _vehicle_id)
    return BeginTripResult.new
  end

  def end_trip(trip)
    ended = Time.now
    duration = (ended - trip.began_at) / 60.0
    return EndTripResult.new(
      cost_cents: trip.vendor_service_rate.calculate_total(duration).cents.to_i,
      cost_currency: "USD",
      end_time: ended,
      duration_minutes: duration.to_i,
    )
  end
end
