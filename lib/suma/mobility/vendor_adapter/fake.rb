# frozen_string_literal: true

class Suma::Mobility::VendorAdapter::Fake
  include Suma::Mobility::VendorAdapter

  class << self
    attr_accessor :uses_deep_linking, :find_anon_proxy_vendor_account_results

    def reset
      self.uses_deep_linking = nil
      self.find_anon_proxy_vendor_account_results = []
    end
  end

  def begin_trip(trip)
    trip.external_trip_id = "fake-" + SecureRandom.hex(4)
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

  def uses_deep_linking? = self.class.uses_deep_linking
  def find_anon_proxy_vendor_account(*) = self.class.find_anon_proxy_vendor_account_results.shift
end
