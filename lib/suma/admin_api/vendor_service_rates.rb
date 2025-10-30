# frozen_string_literal: true

require "suma/admin_api"

class Suma::AdminAPI::VendorServiceRates < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  class DetailedVendorServiceRateEntity < VendorServiceRateEntity
    include Suma::AdminAPI::Entities
    include AutoExposeDetail
    expose :unit_offset
    expose :ordinal
    expose :undiscounted_rate, with: VendorServiceRateEntity
    expose :program_pricings, with: ProgramPricingEntity
  end

  resource :vendor_service_rates do
    Suma::AdminAPI::CommonEndpoints.list(
      self,
      Suma::Vendor::ServiceRate,
      VendorServiceRateEntity,
    )
    Suma::AdminAPI::CommonEndpoints.create(
      self,
      Suma::Vendor::ServiceRate,
      DetailedVendorServiceRateEntity,
    ) do
      params do
        requires :internal_name, type: String
        requires :external_name, type: String
        requires(:unit_amount, type: JSON) { use :money }
        requires(:surcharge, type: JSON) { use :money }
        requires :unit_offset, type: Integer
        optional(:undiscounted_rate, type: JSON) { use :model_with_id }
        optional :ordinal, type: Float, default: 0
      end
    end
    Suma::AdminAPI::CommonEndpoints.get_one(
      self,
      Suma::Vendor::ServiceRate,
      DetailedVendorServiceRateEntity,
    )
    Suma::AdminAPI::CommonEndpoints.update(
      self,
      Suma::Vendor::ServiceRate,
      DetailedVendorServiceRateEntity,
    ) do
      params do
        optional :internal_name, type: String
        optional :external_name, type: String
        optional(:undiscounted_rate, type: JSON) { use :model_with_id }
        optional :ordinal, type: Float, default: 0
      end
    end
  end
end
