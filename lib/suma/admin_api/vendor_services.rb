# frozen_string_literal: true

require "suma/admin_api"

class Suma::AdminAPI::VendorServices < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  class DetailedVendorServiceEntity < VendorServiceEntity
    include Suma::AdminAPI::Entities
    include AutoExposeDetail
    expose :audit_activities, with: ActivityEntity
    expose :mobility_vendor_adapter_key
    expose :charge_after_fulfillment
    expose :vendor_service_categories, as: :categories, with: VendorServiceCategoryEntity
    expose :program_pricings, with: ProgramPricingEntity
    expose_image :image
    expose :constraints

    expose :mobility_vendor_adapter_key_options do |_|
      Suma::Mobility::VendorAdapter.registered_keys
    end
  end

  resource :vendor_services do
    Suma::AdminAPI::CommonEndpoints.list(
      self,
      Suma::Vendor::Service,
      VendorServiceEntity,
    )
    Suma::AdminAPI::CommonEndpoints.create(
      self,
      Suma::Vendor::Service,
      DetailedVendorServiceEntity,
    ) do
      params do
        requires(:vendor, type: JSON) { use :model_with_id }
        requires :image, type: File
        requires(:image_caption, type: JSON) { use :translated_text, allow_blank: true }
        requires :internal_name, type: String
        requires :external_name, type: String
        requires :period_begin, type: Time
        requires :period_end, type: Time
        optional :mobility_vendor_adapter_key, type: String, default: ""
        optional :charge_after_fulfillment, type: Boolean, default: false
        optional :constraints, type: String
      end
    end
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
        optional :internal_name, type: String
        optional :external_name, type: String
        optional :period_begin, type: Time
        optional :period_end, type: Time
        optional :mobility_vendor_adapter_key, type: String
        optional :charge_after_fulfillment, type: Boolean
        optional :constraints, type: String
      end
    end
  end
end
