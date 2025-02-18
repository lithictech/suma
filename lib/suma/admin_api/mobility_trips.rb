# frozen_string_literal: true

require "grape"
require "suma/admin_api"

class Suma::AdminAPI::MobilityTrips < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  class DetailedMobilityTripEntity < MobilityTripEntity
    include Suma::AdminAPI::Entities
    expose :vendor_service, with: VendorServiceEntity
    expose :charge, with: ChargeEntity
    expose :member, with: MemberEntity
  end

  resource :mobility_trips do
    Suma::AdminAPI::CommonEndpoints.list(
      self,
      Suma::Mobility::Trip,
      MobilityTripEntity,
      search_params: [:external_trip_id],
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
        optional :period_begin, type: Time
        optional :period_end, type: Time
        optional :begin_lat, type: Integer
        optional :begin_lng, type: Integer
        optional :end_lat, type: Integer
        optional :end_lng, type: Integer
        optional :began_at, type: Time
        optional :ended_at, type: Time
      end
    end
  end
end
