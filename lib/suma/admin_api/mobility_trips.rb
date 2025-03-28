# frozen_string_literal: true

require "grape"
require "suma/admin_api"

class Suma::AdminAPI::MobilityTrips < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  class DetailedMobilityTripEntity < MobilityTripEntity
    include Suma::AdminAPI::Entities
    include AutoExposeDetail
    expose :external_trip_id
    expose :opaque_id
    expose :begin_lat
    expose :begin_lng
    expose :end_lat, expose_nil: false
    expose :end_lng, expose_nil: false
    expose :vendor_service_rate, as: :rate, with: VendorServiceRateEntity
    expose :discount_amount, with: MoneyEntity, &self.delegate_to(:charge, :discount_amount, safe: true)
    expose :charge, with: ChargeEntity
  end

  resource :mobility_trips do
    Suma::AdminAPI::CommonEndpoints.list(
      self,
      Suma::Mobility::Trip,
      MobilityTripEntity,
    )
    Suma::AdminAPI::CommonEndpoints.get_one(
      self,
      Suma::Mobility::Trip,
      DetailedMobilityTripEntity,
    )
    Suma::AdminAPI::CommonEndpoints.update(
      self,
      Suma::Mobility::Trip,
      DetailedMobilityTripEntity,
    ) do
      params do
        optional :began_at, type: Time
        optional :ended_at, type: Time
        optional :begin_lat, type: Float
        optional :begin_lng, type: Float
        optional :end_lat, type: Float
        optional :end_lng, type: Float
      end
    end
  end
end
