# frozen_string_literal: true

require "suma/lime/maas_client"

class Suma::Mobility::TripProvider::LimeMaas
  include Suma::Mobility::TripProvider

  attr_reader :maas_client

  def initialize
    @maas_client = Suma::Lime::MaasClient.new(Suma::Lime.maas_auth_token)
  end

  def begin_trip(trip)
    lime_user_id = self.maas_client.ensure_member_registered(trip.member)
    resp = self.maas_client.start_trip(
      vehicle_id: trip.vehicle_id,
      user_id: lime_user_id,
      lat: trip.begin_lat,
      lng: trip.begin_lng,
      # TODO: Figure this out
      rate_plan_id: "placeholder",
      at: trip.began_at,
    )
    trip.external_trip_id = resp.dig("data", "id")
    return Suma::Mobility::BeginTripResult.new
  end

  def end_trip(trip)
    resp = self.maas_client.complete_trip(
      trip_id: trip.external_trip_id,
      lat: trip.end_lat,
      lng: trip.end_lng,
      at: trip.ended_at,
    )
    trip.ended_at = resp.dig("data", "completed_at")
    Suma.assert do
      duration = resp.dig("data", "duration_seconds")
      [
        duration == trip.duration.to_i,
        "API duration #{duration} and calculated duration #{trip.duration.to_i} should match",
      ]
    end
    minutes = trip.duration_minutes
    trip_amount = trip.vendor_service_rate.calculate_unit_cost(minutes)
    return Suma::Mobility::EndTripResult.new(
      undiscounted_cost: trip.vendor_service_rate.calculate_undiscounted_total(minutes),
      line_items: [
        Suma::Mobility::EndTripResult::LineItem.new(
          memo: "Unlock fee",
          amount: trip.vendor_service_rate.surcharge,
        ),
        Suma::Mobility::EndTripResult::LineItem.new(
          memo: "Ride cost (#{trip.vendor_service_rate.unit_amount}/min for #{minutes} min)",
          amount: trip_amount,
        ),
      ],
    )
  end
end
