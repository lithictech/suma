# frozen_string_literal: true

require "suma/admin_api"

class Suma::AdminAPI::Programs < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  class ProgramComponentEntity < BaseEntity
    include Suma::AdminAPI::Entities
    expose :key, &self.delegate_to(:name, :en)
    expose :name, with: TranslatedTextEntity
    expose :until
    expose :image, with: ImageEntity
    expose :link
  end

  class DetailedProgramEntity < ProgramEntity
    include Suma::AdminAPI::Entities
    include AutoExposeDetail
    expose :commerce_offerings, with: OfferingEntity
    expose :vendor_services, with: VendorServiceEntity
    expose :components, with: ProgramComponentEntity
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
        requires(:name, type: JSON) { use :translated_text }
        optional :commerce_offerings, type: Array[JSON] do
          use :model_with_id
        end
        optional :vendor_services, type: Array[JSON] do
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
        optional(:name, type: JSON) { use :translated_text }
        optional :commerce_offerings, type: Array[JSON] do
          use :model_with_id
        end
        optional :vendor_services, type: Array[JSON] do
          use :model_with_id
        end
      end
    end
  end
end
