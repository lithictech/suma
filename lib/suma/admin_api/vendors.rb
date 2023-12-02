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
  end

  resource :vendors do
    Suma::AdminAPI::CommonEndpoints.list(
      self,
      Suma::Vendor,
      VendorEntity,
      search_params: [:name, :slug],
    )

    Suma::AdminAPI::CommonEndpoints.create(self, Suma::Vendor, DetailedVendorEntity) do
      params do
        requires :name, type: String, allow_blank: false
      end
    end

    Suma::AdminAPI::CommonEndpoints.get_one(self, Suma::Vendor, DetailedVendorEntity)

    Suma::AdminAPI::CommonEndpoints.update self, Suma::Vendor, DetailedVendorEntity do
      params do
        optional :name, type: String, allow_blank: false
      end
    end
  end
end
