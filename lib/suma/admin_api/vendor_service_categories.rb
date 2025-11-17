# frozen_string_literal: true

require "suma/admin_api"

class Suma::AdminAPI::VendorServiceCategories < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  class ListVendorServiceCategoryEntity < VendorServiceCategoryEntity
    include Suma::AdminAPI::Entities
    expose :parent, with: VendorServiceCategoryEntity
  end

  class DetailedVendorServiceCategoryEntity < VendorServiceCategoryEntity
    include Suma::AdminAPI::Entities
    include AutoExposeDetail
    expose :parent, with: VendorServiceCategoryEntity
    expose :children, with: VendorServiceCategoryEntity
  end

  resource :vendor_service_categories do
    Suma::AdminAPI::CommonEndpoints.list(
      self,
      Suma::Vendor::ServiceCategory,
      ListVendorServiceCategoryEntity,
      ordering_kw: {default: :name},
    )
    Suma::AdminAPI::CommonEndpoints.create(
      self,
      Suma::Vendor::ServiceCategory,
      DetailedVendorServiceCategoryEntity,
    ) do
      params do
        requires :name, type: String
        optional :slug, type: String
        optional(:parent, type: JSON) { use :model_with_id }
      end
    end
    Suma::AdminAPI::CommonEndpoints.get_one(
      self,
      Suma::Vendor::ServiceCategory,
      DetailedVendorServiceCategoryEntity,
    )
    Suma::AdminAPI::CommonEndpoints.update(
      self,
      Suma::Vendor::ServiceCategory,
      DetailedVendorServiceCategoryEntity,
    ) do
      params do
        optional :name, type: String
        optional :slug, type: String
        optional(:parent, type: JSON) { use :model_with_id }
      end
    end
  end
end
