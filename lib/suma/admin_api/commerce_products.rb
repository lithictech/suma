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
    expose :limited_quantity, &self.delegate_to(:inventory!, :limited_quantity)
    expose :quantity_on_hand, &self.delegate_to(:inventory!, :quantity_on_hand)
    expose :quantity_pending_fulfillment, &self.delegate_to(:inventory!, :quantity_pending_fulfillment)
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

    helpers do
      params :product_params do
        optional :image, type: File
        optional :name, type: JSON do
          use :translated_text
        end
        optional :description, type: JSON do
          use :translated_text
        end
        optional :our_cost, allow_blank: false, type: JSON do
          use :funding_money
        end
        optional :vendor, type: JSON do
          requires :id, type: Integer
        end
        optional :vendor_service_category, type: JSON do
          requires :slug, type: String
        end
        optional :max_quantity_per_order, type: Integer
        optional :max_quantity_per_offering, type: Integer
        optional :limited_quantity, type: Boolean
        optional :quantity_on_hand, type: Integer
        optional :quantity_pending_fulfillment, type: Integer
      end

      def update_from_params(product)
        vendor = params.key?(:vendor) &&
          (Suma::Vendor[params[:vendor][:id]] or forbidden!)
        vsc = params.key?(:vendor_service_category) &&
          (Suma::Vendor::ServiceCategory[slug: params[:vendor_service_category][:slug]] or forbidden!)

        (product.name = Suma::TranslatedText.find_or_create(**params[:name])) if params.key?(:name)
        (product.description = Suma::TranslatedText.find_or_create(**params[:description])) if params.key?(:description)
        (product.our_cost = params[:our_cost]) if params.key?(:our_cost)
        (product.vendor = vendor) if vendor
        product.save_changes

        if params.key?(:image)
          uploaded_file = Suma::UploadedFile.create_from_multipart(params[:image])
          if product.images.empty?
            product.add_image({uploaded_file:})
          else
            product.images.first.update(uploaded_file:)
          end
        end

        if vsc
          product.remove_all_vendor_service_categories
          product.add_vendor_service_category(vsc)
        end

        passed_inventory_params = [
          :max_quantity_per_order,
          :max_quantity_per_offering,
          :limited_quantity,
          :quantity_on_hand,
          :quantity_pending_fulfillment,
        ].select { |a| params.key?(a) }
        return if passed_inventory_params.empty?
        inv = product.inventory!
        inv.lock!
        passed_inventory_params.each { |a| inv.set(a => params[a]) }
        inv.save_changes
      end
    end

    params do
      use :product_params
    end
    post :create do
      Suma::Commerce::Product.db.transaction do
        product = Suma::Commerce::Product.new
        update_from_params(product)
        created_resource_headers(product.id, product.admin_link)
        status 200
        present product, with: DetailedProductEntity
      end
    end

    Suma::AdminAPI::CommonEndpoints.get_one(self, Suma::Commerce::Product, DetailedProductEntity)

    route_param :id, type: Integer do
      desc "Update the product"
      params do
        use :product_params
      end
      post do
        (product = Suma::Commerce::Product[params[:id]]) or forbidden!
        product.db.transaction do
          update_from_params(product)
        end
        created_resource_headers(product.id, product.admin_link)
        status 200
        present product, with: DetailedProductEntity
      end
    end
  end
end
