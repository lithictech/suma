# frozen_string_literal: true

require "grape"
require "suma/admin_api"

class Suma::AdminAPI::VendorServices < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  class DetailedVendorServiceEntity < VendorServiceEntity
    include Suma::AdminAPI::Entities
    expose :internal_name
    expose :mobility_vendor_adapter_key
    expose :vendor_service_categories, as: :categories, with: VendorServiceCategoryEntity
    expose :rates, with: VendorServiceRateEntity
    expose :mobility_trips, with: MobilityTripEntity
    expose :image, with: ImageEntity, &self.delegate_to(:images?, :first)
  end

  resource :vendor_services do
    Suma::AdminAPI::CommonEndpoints.list(
      self,
      Suma::Vendor::Service,
      VendorServiceEntity,
      search_params: [:internal_name, :external_name],
    )

    Suma::AdminAPI::CommonEndpoints.get_one(self, Suma::Vendor::Service, DetailedVendorServiceEntity)
  end
end
