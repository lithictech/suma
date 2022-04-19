# frozen_string_literal: true

require "grape_entity"

require "suma/service/entities"
require "suma/api" unless defined? Suma::API

module Suma::API
  AddressEntity = Suma::Service::Entities::Address
  LegalEntityEntity = Suma::Service::Entities::LegalEntityEntity
  MoneyEntity = Suma::Service::Entities::Money
  TimeRangeEntity = Suma::Service::Entities::TimeRange

  class BaseEntity < Suma::Service::Entities::Base; end

  class MobilityMapVehicleEntity < BaseEntity
    expose :c
    expose :p
    expose :d, expose_nil: false
  end

  class OrganizationEntity < BaseEntity
    expose :name
    expose :slug
  end

  class VendorServiceRateEntity < BaseEntity
    expose :id
    expose :message_template
    expose :message_vars
  end

  class VendorServiceEntity < BaseEntity
    expose :id
    expose :external_name, as: :name
    expose :vendor_name, &self.delegate_to(:vendor, :name)
    expose :vendor_slug, &self.delegate_to(:vendor, :slug)
  end

  class MobilityMapEntity < BaseEntity
    expose :precision do |_|
      Suma::Mobility::COORD2INT_FACTOR
    end
    expose :refresh do |_|
      30_000
    end
    expose :providers, with: VendorServiceEntity
    expose :escooter, with: MobilityMapVehicleEntity, expose_nil: false
    expose :ebike, with: MobilityMapVehicleEntity, expose_nil: false
  end

  class MobilityVehicleEntity < BaseEntity
    expose :precision do |_|
      Suma::Mobility::COORD2INT_FACTOR
    end
    expose :vendor_service, with: VendorServiceEntity
    expose :vehicle_id
    expose :to_api_location, as: :loc
  end

  class MobilityTripEntity < BaseEntity
    expose :id
    expose :vehicle_id
    expose :vendor_service, as: :provider, with: VendorServiceEntity
    expose :vendor_service_rate, as: :rate, with: VendorServiceRateEntity
    expose :begin_lat
    expose :begin_lng
    expose :began_at
    expose :end_lat
    expose :end_lng
    expose :ended_at
  end

  class CurrentCustomerEntity < Suma::Service::Entities::CurrentCustomer
    expose :ongoing_trip, with: MobilityTripEntity
  end
end
