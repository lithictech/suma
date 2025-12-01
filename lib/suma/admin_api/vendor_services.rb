# frozen_string_literal: true

require "suma/admin_api"

class Suma::AdminAPI::VendorServices < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  class DetailedVendorServiceEntity < VendorServiceEntity
    include Suma::AdminAPI::Entities
    include AutoExposeDetail
    expose :audit_activities, with: ActivityEntity
    expose :vendor_service_categories, as: :categories, with: VendorServiceCategoryEntity
    expose :program_pricings, with: ProgramPricingEntity
    expose_image :image
    expose :constraints

    expose(:mobility_adapter_present) { |inst| !inst.mobility_adapter.nil? }
    expose :mobility_adapter_trip_provider_key, &self.delegate_to(:mobility_adapter, :trip_provider_key, safe: true)
    expose :mobility_adapter_uses_deep_linking, &self.delegate_to(:mobility_adapter, :uses_deep_linking, safe: true)
    expose :mobility_adapter_send_receipts, &self.delegate_to(:mobility_adapter, :send_receipts, safe: true)

    expose :mobility_adapter_setting
    expose :mobility_adapter_setting_name
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
      around: lambda do |rt, m, &block|
        setting = rt.params.delete(:mobility_adapter_setting)
        block.call
        m.mobility_adapter_setting = setting if setting
      end,
    ) do
      params do
        requires(:vendor, type: JSON) { use :model_with_id }
        requires :image, type: File
        optional(:image_caption, type: JSON) { use :translated_text, allow_blank: true }
        requires :internal_name, type: String
        requires :external_name, type: String
        requires :period_begin, type: Time
        requires :period_end, type: Time
        optional :mobility_adapter_setting, type: String
        optional :constraints, type: String
        optional(:categories, type: Array, coerce_with: lambda(&:values)) { use :model_with_id }
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
        optional :mobility_adapter_setting, type: String
        optional :constraints, type: String
        optional(:categories, type: Array, coerce_with: lambda(&:values)) { use :model_with_id }
      end
    end
  end
end
