# frozen_string_literal: true

require "grape"
require "suma/admin_api"

class Suma::AdminAPI::VendibleGroups < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  class VendibleEntity < BaseEntity
    include Suma::AdminAPI::Entities
    expose :key, &self.delegate_to(:name, :en)
    expose :name, with: TranslatedTextEntity
    expose :until
    expose :image, with: ImageEntity
    expose :link
  end

  class DetailedVendibleGroupEntity < VendibleGroupEntity
    include Suma::AdminAPI::Entities
    expose :commerce_offerings, with: OfferingEntity
    expose :vendibles, with: VendibleEntity
    expose :vendor_services, with: VendorServiceEntity
  end

  resource :vendible_groups do
    params do
      use :pagination
      use :ordering, model: Suma::Vendible::Group, default: :ordinal
      use :searchable
    end
    get do
      check_role_access!(admin_member, :read, :admin_commerce)
      ds = Suma::Vendible::Group.dataset
      if (name_en_like = search_param_to_sql(params, :name_en))
        name_es_like = search_param_to_sql(params, :name_es)
        ds = ds.translation_join(:name, [:en, :es])
        ds = ds.reduce_expr(:|, [name_en_like, name_es_like])
      end
      ds = order(ds, params)
      ds = paginate(ds, params)
      present_collection ds, with: VendibleGroupEntity
    end

    Suma::AdminAPI::CommonEndpoints.create(
      self,
      Suma::Vendible::Group,
      DetailedVendibleGroupEntity,
      access: Suma::Member::RoleAccess::ADMIN_COMMERCE,
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
      Suma::Vendible::Group,
      DetailedVendibleGroupEntity,
      access: Suma::Member::RoleAccess::ADMIN_COMMERCE,
    )

    Suma::AdminAPI::CommonEndpoints.update(
      self,
      Suma::Vendible::Group,
      DetailedVendibleGroupEntity,
      access: Suma::Member::RoleAccess::ADMIN_COMMERCE,
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
