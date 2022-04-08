# frozen_string_literal: true

require "grape_entity"

require "suma/service/entities"
require "suma/api" unless defined? Suma::API

module Suma::API
  AddressEntity = Suma::Service::Entities::Address
  CurrentCustomerEntity = Suma::Service::Entities::CurrentCustomer
  LegalEntityEntity = Suma::Service::Entities::LegalEntityEntity
  MoneyEntity = Suma::Service::Entities::Money
  TimeRangeEntity = Suma::Service::Entities::TimeRange

  class BaseEntity < Suma::Service::Entities::Base; end

  class MobilityMapVehicleEntity < BaseEntity
    expose :c
    expose :p
    expose :d, expose_nil: false
  end

  class PlatformPartnerEntity < BaseEntity
    expose :name
    expose :short_slug
  end

  class MobilityMapEntity < BaseEntity
    expose :precision do |_|
      Suma::MobilityVehicle::COORD2INT_FACTOR
    end
    expose :refresh do |_|
      30_000
    end
    expose :providers, with: PlatformPartnerEntity
    expose :escooter, with: MobilityMapVehicleEntity, expose_nil: false
    expose :ebike, with: MobilityMapVehicleEntity, expose_nil: false
  end

  class MobilityVehicleEntity < BaseEntity
    expose :precision do |_|
      Suma::MobilityVehicle::COORD2INT_FACTOR
    end
    expose :platform_partner, with: PlatformPartnerEntity
    expose :vehicle_id
    expose :to_api_location, as: :loc
  end
end
