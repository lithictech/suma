# frozen_string_literal: true

require "grape"
require "suma/admin_api"

class Suma::AdminAPI::CommerceProducts < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  class OfferingProductWithOfferingEntity < OfferingProductEntity
    include Suma::AdminAPI::Entities
    include AutoExposeBase
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
    expose :image, with: ImageEntity, &self.delegate_to(:images?, :first)
    expose :vendor_service_category, &self.delegate_to(:vendor_service_categories, :first)
  end

  resource :commerce_products do
    Suma::AdminAPI::CommonEndpoints.list(
      self,
      Suma::Commerce::Product,
      ProductEntity,
      translation_search_params: [:name],
    )

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
      requires :vendor_name, type: String
      requires :vendor_service_category_slug, type: String
      requires :max_quantity_per_order, type: Integer
      requires :max_quantity_per_offering, type: Integer
    end
    post :create do
      (vendor = Suma::Vendor[name: params[:vendor_name]]) or forbidden!
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
      desc "Update the product"
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
        requires :vendor_name, type: String
        requires :vendor_service_category_slug, type: String
        requires :max_quantity_per_order, type: Integer
        requires :max_quantity_per_offering, type: Integer
      end
      post do
        product = Suma::Commerce::Product[params[:id]]
        product.db.transaction do
          (vendor = Suma::Vendor[name: params[:vendor_name]]) or forbidden!
          (vsc = Suma::Vendor::ServiceCategory[slug: params[:vendor_service_category_slug]]) or forbidden!
          product.remove_all_vendor_service_categories
          product.add_vendor_service_category(vsc)

          uploaded_file = Suma::UploadedFile.create_from_multipart(params[:image])
          product.images.first.update(uploaded_file:)
          product.save_changes

          product.update(
            name: Suma::TranslatedText.find_or_create(**params[:name]),
            description: Suma::TranslatedText.find_or_create(**params[:description]),
            our_cost: params[:our_cost],
            vendor:,
          )
          product.inventory!.update(
            max_quantity_per_order: params[:max_quantity_per_order],
            max_quantity_per_offering: params[:max_quantity_per_offering],
          )
        end
        created_resource_headers(product.id, product.admin_link)
        status 200
        present product, with: DetailedProductEntity
      end
    end

    Suma::AdminAPI::CommonEndpoints.get_one(self, Suma::Commerce::Product, DetailedProductEntity)
  end
end
