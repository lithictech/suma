# frozen_string_literal: true

require "grape"
require "suma/admin_api"

class Suma::AdminAPI::Programs < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  class DetailedProgramEntity < ProgramEntity
    include Suma::AdminAPI::Entities
    include AutoExposeDetail
    expose :image, with: ImageEntity, &self.delegate_to(:images?, :first)
    expose :lyft_pass_program_id
    expose :commerce_offerings, with: OfferingEntity
    expose :vendor_services, with: VendorServiceEntity
    expose :anon_proxy_vendor_configurations, as: :configurations, with: VendorConfigurationEntity
    expose :payment_triggers, with: PaymentTriggerEntity
    expose :enrollments, with: ProgramEnrollmentEntity
  end

  resource :programs do
    params do
      use :pagination
      use :ordering, model: Suma::Program, default: :ordinal
      use :searchable
    end
    get do
      check_role_access!(admin_member, :read, :admin_commerce)
      ds = Suma::Program.dataset
      if (name_en_like = search_param_to_sql(params, :name_en))
        name_es_like = search_param_to_sql(params, :name_es)
        ds = ds.translation_join(:name, [:en, :es])
        ds = ds.reduce_expr(:|, [name_en_like, name_es_like])
      end
      ds = order(ds, params)
      ds = paginate(ds, params)
      present_collection ds, with: ProgramEntity
    end

    Suma::AdminAPI::CommonEndpoints.create(
      self,
      Suma::Program,
      DetailedProgramEntity,
    ) do
      params do
        requires :image, type: File
        requires(:name, type: JSON) { use :translated_text }
        requires(:description, type: JSON) { use :translated_text }
        requires :app_link, type: String
        requires(:app_link_text, type: JSON) { use :translated_text }
        requires :period_begin, type: Time
        requires :period_end, type: Time
        optional :ordinal, type: Integer
        optional :commerce_offerings, type: Array, coerce_with: proc(&:values) do
          use :model_with_id
        end
        optional :vendor_services, type: Array, coerce_with: proc(&:values) do
          use :model_with_id
        end
      end
    end

    Suma::AdminAPI::CommonEndpoints.get_one(
      self,
      Suma::Program,
      DetailedProgramEntity,
    )

    Suma::AdminAPI::CommonEndpoints.update(
      self,
      Suma::Program,
      DetailedProgramEntity,
      around: lambda do |rt, m, &block|
        offerings = rt.params.delete(:commerce_offerings)
        vendor_services = rt.params.delete(:vendor_services)
        block.call
        if offerings
          offering_models = Suma::Commerce::Offering.where(id: offerings.map { |o| o[:id] }).all
          m.replace_commerce_offerings(offering_models)
        end
        if vendor_services
          vendor_service_models = Suma::Vendor::Service.where(id: vendor_services.map { |o| o[:id] }).all
          m.replace_vendor_services(vendor_service_models)
        end
      end,
    ) do
      params do
        optional :image, type: File
        optional(:name, type: JSON) { use :translated_text }
        optional(:description, type: JSON) { use :translated_text }
        optional :app_link, type: String
        optional(:app_link_text, type: JSON) { use :translated_text }
        optional :period_begin, type: Time
        optional :period_end, type: Time
        optional :ordinal, type: Integer
        optional :commerce_offerings, type: Array, coerce_with: proc(&:values) do
          use :model_with_id
        end
        optional :vendor_services, type: Array, coerce_with: proc(&:values) do
          use :model_with_id
        end
      end
    end
  end
end
