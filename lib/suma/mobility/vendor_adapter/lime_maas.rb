# frozen_string_literal: true

class Suma::Mobility::VendorAdapter::LimeMaas
  include Suma::Mobility::VendorAdapter

  def begin_trip(trip)
    lime_user_id = Suma::Lime.ensure_member_registered(trip.member)
    resp = Suma::Lime.start_trip(
      vehicle_id: trip.vehicle_id,
      user_id: lime_user_id,
      lat: trip.begin_lat,
      lng: trip.begin_lng,
      # TODO: Figure this out
      rate_plan_id: "placeholder",
      at: trip.began_at,
    )
    trip.external_trip_id = resp.dig("data", "id")
    return BeginTripResult.new(raw_result: resp)
  end

  def end_trip(trip)
    resp = Suma::Lime.complete_trip(
      trip_id: trip.external_trip_id,
      lat: trip.end_lat,
      lng: trip.end_lng,
      at: trip.ended_at,
    )
    duration = resp.dig("data", "duration_seconds") / 60.0
    return EndTripResult.new(
      cost_cents: trip.vendor_service_rate.calculate_total(duration).cents.to_i,
      cost_currency: "USD",
      end_time: resp.dig("data", "completed_at"),
      duration_minutes: duration.ceil,
    )
  end

  def uses_deep_linking? = false
end
