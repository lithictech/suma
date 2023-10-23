# frozen_string_literal: true

require "grape"
require "suma/admin_api"

class Suma::AdminAPI::CommerceProducts < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  resource :commerce_products do
    params do
      use :pagination
      use :ordering, model: Suma::Commerce::Product
      use :searchable
    end
    get do
      ds = Suma::Commerce::Product.dataset
      if (nameen_like = search_param_to_sql(params, :name_en))
        namees_like = search_param_to_sql(params, :name_es)
        ds = ds.translation_join(:name, [:en, :es]).where(nameen_like | namees_like)
      end
      # TODO: translation join doesn't work for multiple search terms
      ds = order(ds, params)
      ds = paginate(ds, params)
      present_collection ds, with: ProductEntity
    end

    params do
      requires :image, type: File
      requires :name, type: JSON do
        use :translated_text
      end
      requires :description, type: JSON do
        use :translated_text
      end
      requires :our_cost, allow_blank: false, type: JSON do
        use :funding_money
      end
      requires :vendor_id, type: Integer
      requires :vendor_service_category_slug, type: String
      requires :max_quantity_per_order, type: Integer
      requires :max_quantity_per_offering, type: Integer
    end
    post :create do
      (vendor = Suma::Vendor[params[:vendor_id]]) or forbidden!
      (vsc = Suma::Vendor::ServiceCategory[slug: params[:vendor_service_category_slug]]) or forbidden!
      product = Suma::Commerce::Product.create(
        name: Suma::TranslatedText.find_or_create(**params[:name]),
        description: Suma::TranslatedText.find_or_create(**params[:description]),
        our_cost: params[:our_cost],
        vendor:,
      )
      product.add_vendor_service_category(vsc)
      uploaded_file = Suma::UploadedFile.create_from_multipart(params[:image])
      product.add_image({uploaded_file:})

      Suma::Commerce::ProductInventory.create(
        product:,
        max_quantity_per_order: params[:max_quantity_per_order],
        max_quantity_per_offering: params[:max_quantity_per_offering],
      )
      created_resource_headers(product.id, product.admin_link)
      status 200
      present product, with: DetailedProductEntity
    end

    route_param :id, type: Integer do
      helpers do
        def lookup
          (co = Suma::Commerce::Product[params[:id]]) or forbidden!
          return co
        end
      end

      get do
        co = lookup
        present co, with: DetailedProductEntity
      end
    end
  end

  class ProductEntity < BaseEntity
    include Suma::AdminAPI::Entities
    include AutoExposeBase
    expose :vendor, with: VendorEntity
    expose_translated :name
    expose_translated :description
  end

  class OfferingProductWithOfferingEntity < OfferingProductEntity
    include Suma::AdminAPI::Entities
    expose :offering, with: OfferingEntity
  end

  class DetailedProductEntity < ProductEntity
    include Suma::AdminAPI::Entities
    include AutoExposeDetail
    expose :our_cost, with: MoneyEntity
    expose :max_quantity_per_order, &self.delegate_to(:inventory!, :max_quantity_per_order)
    expose :max_quantity_per_offering, &self.delegate_to(:inventory!, :max_quantity_per_offering)
    expose :offerings, with: OfferingEntity
    expose :orders, with: OrderEntity
    expose :offering_products, with: OfferingProductWithOfferingEntity
  end
end
