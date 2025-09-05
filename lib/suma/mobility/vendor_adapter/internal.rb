# frozen_string_literal: true

# A 'working' vendor adapter that can be used for testing purposes,
# since it can be difficult or impossible to test with external platforms easily.
# Note you'll need to do all the normal rigamarole to set this up for use, including:
# - Create the vendor
# - Create the vendor service (use charge-after-fulfillment if not worrying about charging)
# - Create the vendor service rate (use $0 if not worrying about charging)
# - Assign the vendor service to a program so it's available.
# - Create vehicles. You can use code like:
#       Suma::Mobility::Vehicle.multi_insert(Suma::Mobility::Vehicle.naked.all.each do |h|
#         h.delete(:id)
#         h[:vehicle_id] = "suma-#{h[:vehicle_id]}"
#         h[:vendor_service_id] = fake_vs.id
#       end)
#
# See bootstrap.rb for example code on fixturing resources.
class Suma::Mobility::VendorAdapter::Internal
  include Suma::Mobility::VendorAdapter

  VENDOR_NAME = "Suma-Internal-Testing"

  def begin_trip(trip)
    trip.external_trip_id = "internal-" + SecureRandom.hex(4)
    return BeginTripResult.new
  end

  def end_trip(trip)
    ended = Time.now
    duration = (ended - trip.began_at) / 60.0
    return EndTripResult.new(
      cost: trip.vendor_service_rate.calculate_total(duration),
      undiscounted: trip.vendor_service_rate.calculate_undiscounted_total(duration),
      end_time: ended,
      duration_minutes: duration.to_i,
    )
  end

  def uses_deep_linking? = false
end
