# frozen_string_literal: true

require "grape"
require "suma/api"
require "suma/service/entities"

class Suma::API::Commerce < Suma::API::V1
  include Suma::Service::Types
  include Suma::API::Entities

  resource :commerce do
    resource :offerings do
      desc "Return all commerce offerings that are not closed"
      get do
        t = Time.now
        ds = Suma::Commerce::Offering.available_at(t)
        present_collection ds, with: CommerceOfferingEntity
      end

      route_param :offering_id, type: Integer do
        desc "Returns all commerce offering products"
        resource :products do
          get do
            ds = Suma::Commerce::OfferingProduct.available_with(params[:offering_id])
            present_collection ds, with: CommerceOfferingProductListEntity
          end
          route_param :product_id, type: Integer do
            desc "Return one commerce offering product"
            get do
              (product = Suma::Commerce::OfferingProduct[product_id: params[:product_id],
                                                         offering_id: params[:offering_id]]) or forbidden!
              present product, with: CommerceOfferingProductDetailEntity
            end
          end
        end
      end
    end
  end

  class VendorEntity < BaseEntity
    expose :id
    expose :name
  end

  class CommerceOfferingEntity < BaseEntity
    expose :id
    expose :description
    expose :period_end, as: :closes_at
  end

  module CommerceOfferingProductMixin
    def self.included(m)
      m.expose :name, &m.delegate_to(:product, :name)
      m.expose :description, &m.delegate_to(:product, :description)
      m.expose :product_id
      m.expose :offering_id
      m.expose :discounted?, as: :is_discounted
      m.expose :customer_price, with: Suma::Service::Entities::Money
      m.expose :undiscounted_price, with: Suma::Service::Entities::Money
    end
  end

  class CommerceOfferingProductListEntity < BaseEntity
    include CommerceOfferingProductMixin
    # We should remove this and add it as a top-level field on the collection response
    expose :offering_description, &self.delegate_to(:offering, :description)
    expose :image, with: Suma::API::Entities::ImageEntity, &self.delegate_to(:product, :images, :first)
  end

  class CommerceOfferingProductDetailEntity < BaseEntity
    include CommerceOfferingProductMixin
    expose :vendor, with: VendorEntity, &self.delegate_to(:product, :vendor)
    expose :images, with: Suma::API::Entities::ImageEntity, &self.delegate_to(:product, :images)
  end
end
