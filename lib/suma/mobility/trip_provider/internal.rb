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
class Suma::Mobility::TripProvider::Internal
  include Suma::Mobility::TripProvider

  VENDOR_NAME = "Suma-Internal-Testing"

  def begin_trip(trip)
    trip.external_trip_id = "internal-" + SecureRandom.hex(4)
    return Suma::Mobility::BeginTripResult.new
  end

  def end_trip(trip)
    minutes = trip.duration_minutes
    trip_amount = trip.vendor_service_rate.calculate_unit_cost(minutes)
    return Suma::Mobility::EndTripResult.new(
      undiscounted_cost: trip.vendor_service_rate.calculate_undiscounted_total(minutes),
      charge_at: Time.now,
      line_items: [
        Suma::Mobility::EndTripResult::LineItem.new(
          memo: Suma::I18n::StaticString.find_text("backend", "trip_receipt_unlock_fee"),
          amount: trip.vendor_service_rate.surcharge,
        ),
        Suma::Mobility::EndTripResult::LineItem.new(
          memo: Suma::I18n::StaticString.find_text("backend", "trip_receipt_ride_cost").
            format(unit_amount: trip.vendor_service_rate.unit_amount, minutes:),
          amount: trip_amount,
        ),
      ],
    )
  end
end
