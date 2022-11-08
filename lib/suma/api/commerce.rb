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
        current_member
        t = Time.now
        ds = Suma::Commerce::Offering.available_at(t)
        present_collection ds, with: OfferingEntity
      end

      route_param :offering_id, type: Integer do
        helpers do
          def lookup_offering!
            (offering = Suma::Commerce::Offering[params[:offering_id]]) or forbidden!
            return offering
          end

          def lookup_cart!(offering)
            return Suma::Commerce::Cart.lookup(member: current_member, offering:)
          end
        end

        params do
          requires :product_id, type: Integer
          requires :quantity, type: Integer
          optional :timestamp, type: Float, allow_blank: true
        end
        put :cart_item do
          offering = lookup_offering!
          cart = lookup_cart!(offering)
          product = Suma::Commerce::Product[params[:product_id]]
          begin
            cart.set_item(product, params[:quantity], timestamp: params[:timestamp])
          rescue Suma::Commerce::Cart::ProductUnavailable
            merror!(409, "Product is not available", code: "product_unavailable")
          rescue Suma::Commerce::Cart::OutOfOrderUpdate
            self.logger.info "out_of_order_update", product_id: product&.id, quantity: params[:quantity]
            nil
          end
          present offering, with: OfferingWithCartEntity, cart:
        end

        resource :products do
          get do
            current_member
            offering = lookup_offering!
            ds = offering.offering_products_dataset.available
            present_collection ds, with: OfferingProductListWithCartEntity, offering:, cart: lookup_cart!(offering)
          end
        end
      end
    end
  end

  class VendorEntity < BaseEntity
    expose :id
    expose :name
  end

  module OfferingProductMixin
    def self.apply(m, to_product, to_offpro)
      m.expose_translated :name, &m.delegate_to(*to_product, :name)
      m.expose_translated :description, &m.delegate_to(*to_product, :description)
      m.expose :product_id, &m.delegate_to(*to_product, :id)

      m.expose :is_discounted, &m.delegate_to(*to_offpro, :discounted?, safe_with_default: false)
      m.expose :customer_price,
               with: Suma::Service::Entities::Money,
               &m.delegate_to(*to_offpro, :customer_price, safe_with_default: Money.new(0))
      m.expose :undiscounted_price,
               with: Suma::Service::Entities::Money,
               &m.delegate_to(*to_offpro, :undiscounted_price, safe_with_default: Money.new(0))
    end
  end

  class CartItemEntity < BaseEntity
    expose :quantity
    OfferingProductMixin.apply(self, [:product], [:offering_product])
  end

  class CartEntity < BaseEntity
    expose :items, with: CartItemEntity
  end

  module CartMixin
    def self.included(m)
      m.expose :cart, with: CartEntity do |_inst, opts|
        opts[:cart] or raise "present with 'cart: lookup_cart!'"
      end
    end
  end

  class OfferingEntity < BaseEntity
    expose :id
    expose_translated :description
    expose :period_end, as: :closes_at
    expose :image, with: Suma::API::Entities::ImageEntity, &self.delegate_to(:images?, :first)
  end

  class OfferingWithCartEntity < BaseEntity
    expose :offering, with: OfferingEntity do |instance|
      instance
    end
    include CartMixin
  end

  class OfferingProductListItemEntity < BaseEntity
    OfferingProductMixin.apply(self, [:product], [])
    expose :vendor, with: VendorEntity, &self.delegate_to(:product, :vendor)
    expose :images, with: Suma::API::Entities::ImageEntity, &self.delegate_to(:product, :images?)
  end

  class OfferingProductListWithCartEntity < Suma::Service::Collection::BaseEntity
    expose :items, with: OfferingProductListItemEntity
    expose :offering, with: OfferingEntity do |_, options|
      options.fetch(:offering)
    end
    include CartMixin
  end
end
