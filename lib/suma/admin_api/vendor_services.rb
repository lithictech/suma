# frozen_string_literal: true

require "grape"
require "suma/admin_api"

class Suma::AdminAPI::VendorServices < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  class DetailedMobilityTripEntity < BaseEntity
    include Suma::AdminAPI::Entities
    include AutoExposeBase
    expose :vehicle_id
    expose :vendor_service_rate, as: :rate, with: VendorServiceRateEntity
    expose :begin_lat
    expose :begin_lng
    expose :began_at
    expose :end_lat
    expose :end_lng
    expose :ended_at
    expose :total_cost, with: MoneyEntity, &self.delegate_to(:charge, :discounted_subtotal, safe: true)
    expose :discount_amount, with: MoneyEntity, &self.delegate_to(:charge, :discount_amount, safe: true)
  end

  class DetailedVendorServiceEntity < VendorServiceEntity
    include Suma::AdminAPI::Entities
    expose :internal_name
    expose :mobility_vendor_adapter_key
    expose :vendor_service_categories, as: :categories, with: VendorServiceCategoryEntity
    expose :rates, with: VendorServiceRateEntity
    expose :mobility_trips, with: DetailedMobilityTripEntity
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

    Suma::AdminAPI::CommonEndpoints.eligibilities(
      self,
      Suma::Vendor::Service,
      DetailedVendorServiceEntity,
    )
  end
end
