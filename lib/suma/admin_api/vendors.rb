# frozen_string_literal: true

require "grape"
require "suma/admin_api"

class Suma::AdminAPI::Vendors < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  class DetailedVendorEntity < VendorEntity
    include Suma::AdminAPI::Entities
    include AutoExposeDetail
    expose :slug
    expose :services, with: VendorServiceEntity
    expose :products, with: ProductEntity
    expose :configurations, with: VendorConfigurationEntity
    expose_image :image
  end

  resource :vendors do
    Suma::AdminAPI::CommonEndpoints.list(
      self,
      Suma::Vendor,
      VendorEntity,
    )

    Suma::AdminAPI::CommonEndpoints.create(
      self,
      Suma::Vendor,
      DetailedVendorEntity,
    ) do
      params do
        requires :name, type: String, allow_blank: false
        requires :image, type: File
        optional(:image_caption, type: JSON) { use :translated_text, allow_blank: true }
      end
    end

    Suma::AdminAPI::CommonEndpoints.get_one(
      self,
      Suma::Vendor,
      DetailedVendorEntity,
    )

    Suma::AdminAPI::CommonEndpoints.update(
      self,
      Suma::Vendor,
      DetailedVendorEntity,
    ) do
      params do
        optional :name, type: String, allow_blank: false
        optional :image, type: File
        optional(:image_caption, type: JSON) { use :translated_text, allow_blank: true }
      end
    end

    Suma::AdminAPI::CommonEndpoints.destroy(
      self,
      Suma::Vendor,
      DetailedVendorEntity,
    )
  end
end
