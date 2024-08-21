# frozen_string_literal: true

require "grape"
require "suma/admin_api"

class Suma::AdminAPI::Vendors < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  class DetailedVendorEntity < VendorEntity
    include Suma::AdminAPI::Entities
    expose :slug
    expose :services, with: VendorServiceEntity
    expose :products, with: ProductEntity
    expose :configurations, with: VendorConfigurationEntity
    expose :image, with: ImageEntity, &self.delegate_to(:images?, :first)
  end

  resource :vendors do
    Suma::AdminAPI::CommonEndpoints.list(
      self,
      Suma::Vendor,
      VendorEntity,
      access: Suma::Member::RoleAccess::ADMIN_COMMERCE,
      search_params: [:name, :slug],
    )

    Suma::AdminAPI::CommonEndpoints.create(
      self,
      Suma::Vendor,
      DetailedVendorEntity,
      access: Suma::Member::RoleAccess::ADMIN_COMMERCE,
    ) do
      params do
        requires :image, type: File
        requires :name, type: String, allow_blank: false
      end
    end

    Suma::AdminAPI::CommonEndpoints.get_one(
      self,
      Suma::Vendor,
      DetailedVendorEntity,
      access: Suma::Member::RoleAccess::ADMIN_COMMERCE,
    )

    Suma::AdminAPI::CommonEndpoints.update(
      self,
      Suma::Vendor,
      DetailedVendorEntity,
      access: Suma::Member::RoleAccess::ADMIN_COMMERCE,
    ) do
      params do
        optional :image, type: File
        optional :name, type: String, allow_blank: false
      end
    end
  end
end
