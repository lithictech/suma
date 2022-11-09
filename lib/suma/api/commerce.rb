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

        # Return offering and product info.
        # If we need paginated offering items, we can add an endpoint that just returns
        # paginated items after the first page.
        get do
          current_member
          offering = lookup_offering!
          items = offering.offering_products_dataset.available.all
          cart = lookup_cart!(offering)
          vendors = items.map(&:product).map(&:vendor).uniq(&:id)
          present offering, with: OfferingWithContextEntity, cart:, items:, vendors:
        end

        resource :cart do
          params do
            requires :product_id, type: Integer
            requires :quantity, type: Integer
            optional :timestamp, type: Float, allow_blank: true
          end
          put :item do
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
            present cart, with: CartEntity
          end
        end
      end
    end
  end

  class VendorEntity < BaseEntity
    expose :id
    expose :name
  end

  class CartItemEntity < BaseEntity
    expose :quantity
    expose :product_id
  end

  class CartEntity < BaseEntity
    expose :items, with: CartItemEntity
  end

  class OfferingEntity < BaseEntity
    expose :id
    expose_translated :description
    expose :period_end, as: :closes_at
    expose :image, with: Suma::API::Entities::ImageEntity, &self.delegate_to(:images?, :first)
  end

  class OfferingProductEntity < BaseEntity
    expose_translated :name, &self.delegate_to(:product, :name)
    expose_translated :description, &self.delegate_to(:product, :description)
    expose :product_id, &self.delegate_to(:product, :id)
    expose :vendor_id, &self.delegate_to(:product, :vendor_id)
    expose :images, with: Suma::API::Entities::ImageEntity, &self.delegate_to(:product, :images?)

    expose :is_discounted, &self.delegate_to(:discounted?, safe_with_default: false)
    expose :customer_price,
           with: Suma::Service::Entities::Money,
           &self.delegate_to(:customer_price, safe_with_default: Money.new(0))
    expose :undiscounted_price,
           with: Suma::Service::Entities::Money,
           &self.delegate_to(:undiscounted_price, safe_with_default: Money.new(0))
  end

  class OfferingWithContextEntity < BaseEntity
    expose :offering, with: OfferingEntity do |instance|
      instance
    end
    expose :items, with: OfferingProductEntity do |_, opts|
      opts.fetch(:items)
    end
    expose :vendors, with: VendorEntity do |_, opts|
      opts.fetch(:vendors)
    end
    expose :cart, with: CartEntity do |_, opts|
      opts.fetch(:cart)
    end
  end
end
