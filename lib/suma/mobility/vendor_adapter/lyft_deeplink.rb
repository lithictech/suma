# frozen_string_literal: true

require "suma/lyft"

class Suma::Mobility::VendorAdapter::LyftDeeplink
  include Suma::Mobility::VendorAdapter

  def requires_vendor_account? = false
  def uses_deep_linking? = true

  def find_anon_proxy_vendor_account(member)
    vendor = Suma::Vendor.where(name: Suma::Lyft::VENDOR_NAME)
    configuration = Suma::AnonProxy::VendorConfiguration.where(vendor:)
    account = Suma::AnonProxy::VendorAccount.where(configuration:, member:)
    return account.first
  end

  def begin_trip(_trip)
    return Suma::Mobility::VendorAdapter::BeginTripResult.new
  end

  def end_trip(_trip, ride_response:)
    start_time = Time.at(ride_response.fetch("ride").fetch("pickup").fetch("timestamp_ms") / 1000)
    end_time = Time.at(ride_response.fetch("ride").fetch("dropoff").fetch("timestamp_ms") / 1000)
    zero_money = Money.new(0, ride_response.fetch("money").fetch("currency"))
    total_of_non_promo_items = ride_response.fetch("ride").fetch("line_items").sum(zero_money) do |li|
      next 0 if li.fetch("title") == "Promo applied"
      Money.new(li.fetch("money").fetch("amount"), li.fetch("money").fetch("currency"))
    end
    return Suma::Mobility::VendorAdapter::EndTripResult.new(
      cost_cents: total_of_non_promo_items.cents,
      cost_currency: total_of_non_promo_items.currency,
      end_time:,
      duration_minutes: (end_time - start_time).minutes,
    )
  end
end
