# frozen_string_literal: true

require "grape"
require "suma/admin_api"

class Suma::AdminAPI::VendorServices < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  class DetailedMobilityTripEntity < MobilityTripEntity
    include Suma::AdminAPI::Entities
    include AutoExposeDetail
    expose :begin_lat
    expose :begin_lng
    expose :end_lat
    expose :end_lng
    expose :vendor_service_rate, as: :rate, with: VendorServiceRateEntity
    expose :discount_amount, with: MoneyEntity, &self.delegate_to(:charge, :discount_amount, safe: true)
  end

  class DetailedVendorServiceEntity < VendorServiceEntity
    include Suma::AdminAPI::Entities
    include AutoExposeDetail
    expose :audit_activities, with: ActivityEntity
    expose :programs, with: ProgramEntity
    expose :external_name
    expose :internal_name
    expose :mobility_vendor_adapter_key
    expose :charge_after_fulfillment
    expose :vendor_service_categories, as: :categories, with: VendorServiceCategoryEntity
    expose :rates, with: VendorServiceRateEntity
    expose :mobility_trips, with: DetailedMobilityTripEntity
    expose_image :image
  end

  resource :vendor_services do
    Suma::AdminAPI::CommonEndpoints.list(
      self,
      Suma::Vendor::Service,
      VendorServiceEntity,
    )
    Suma::AdminAPI::CommonEndpoints.get_one(
      self,
      Suma::Vendor::Service,
      DetailedVendorServiceEntity,
    )
    Suma::AdminAPI::CommonEndpoints.update(
      self,
      Suma::Vendor::Service,
      DetailedVendorServiceEntity,
    ) do
      params do
        optional :image, type: File
        optional(:image_caption, type: JSON) { use :translated_text, allow_blank: true }
        optional :external_name, type: String
        optional :period_begin, type: Time
        optional :period_end, type: Time
      end
    end
    Suma::AdminAPI::CommonEndpoints.programs_update(
      self,
      Suma::Vendor::Service,
      DetailedVendorServiceEntity,
    )
  end
end
