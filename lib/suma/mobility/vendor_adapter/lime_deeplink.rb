# frozen_string_literal: true

require "suma/lime"

class Suma::Mobility::VendorAdapter::LimeDeeplink
  include Suma::Mobility::VendorAdapter

  def requires_vendor_account? = true
  def uses_deep_linking? = true

  def find_anon_proxy_vendor_account(member)
    vendor = Suma::Lime.deeplink_vendor
    configuration = Suma::AnonProxy::VendorConfiguration.where(vendor:)
    account = Suma::AnonProxy::VendorAccount.where(configuration:, member:)
    return account.first
  end

  def begin_trip(_trip)
    return Suma::Mobility::VendorAdapter::BeginTripResult.new
  end

  class RideReceipt < Suma::TypedStruct
    attr_accessor :ride_id,
                  :vehicle_type,
                  :started_at,
                  :ended_at,
                  :total,
                  :discount,
                  :line_items
  end

  def end_trip(_trip, receipt:)
    return Suma::Mobility::VendorAdapter::EndTripResult.new(
      cost: receipt.total,
      undiscounted: receipt.discount + receipt.total,
      end_time: receipt.ended_at,
      duration_minutes: ((receipt.ended_at - receipt.started_at) / 60.0).to_i,
    )
  end
end
