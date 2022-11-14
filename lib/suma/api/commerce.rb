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

        post :checkout do
          member = current_member
          offering = lookup_offering!
          cart = lookup_cart!(offering)
          cart.db.transaction do
            cart.lock!
            cart.member.commerce_carts.map(&:checkouts).flatten.select(&:editable?).each(&:soft_delete)
            checkout = Suma::Commerce::Checkout.create(
              cart:,
              fulfillment_option: offering.fulfillment_options.first,
              payment_instrument: member.default_payment_instrument,
            )
            cart_items = cart.items.select(&:available?)
            merror!(409, "no items in cart", code: "checkout_no_items") if cart_items.empty?
            cart_items.each do |item|
              checkout.add_item({quantity: item.quantity, offering_product: item.offering_product})
            end
            status 200
            present checkout, with: CheckoutEntity
          end
        end
      end
    end

    resource :checkouts do
      route_param :id, type: Integer do
        helpers do
          def lookup!
            (ch = Suma::Commerce::Checkout[params[:id]]) or forbidden!
            forbidden! unless ch.cart.member === current_member
            return ch
          end

          def lookup_editable!
            ch = lookup!
            raise forbidden! unless ch.editable?
            return ch
          end
        end

        get do
          checkout = lookup_editable!
          present checkout, with: CheckoutEntity
        end

        params do
          optional :payment_instrument, type: JSON do
            use :payment_instrument
          end
          optional :fulfillment_option_id, type: Integer
          optional :save_payment_instrument, type: Boolean, allow_blank: false
        end
        post :complete do
          member = current_member
          checkout = lookup!
          checkout.db.transaction do
            checkout.lock!

            raise merror!(409, "not editable", code: "checkout_fatal_error") unless checkout.editable?

            if (instrument = find_payment_instrument?(member, params[:payment_instrument]))
              checkout.payment_instrument = instrument
            end
            forbidden!("Must have a payment instrument") if checkout.payment_instrument.nil?

            if (fuloptid = params[:fulfillment_option_id])
              fulopt = checkout.cart.offering.fulfillment_options_dataset[fuloptid]
              merror!(403, "Fulfillment option not found", code: "resource_not_found") unless fulopt
              checkout.fulfillment_option = fulopt
            end

            checkout.save_payment_instrument = params[:save_payment_instrument] if
              params.key?(:save_payment_instrument)

            checkout.save_changes
            Suma::Commerce::Order.create(checkout:)
            checkout.cart.items_dataset.delete
            checkout.payment_instrument.soft_delete unless checkout.save_payment_instrument
            checkout.complete.save_changes
          end
          status 200
          present checkout, with: CheckoutConfirmationEntity
        end

        get :confirmation do
          checkout = lookup!
          forbidden! unless checkout.completed?
          forbidden! unless checkout.expose_for_confirmation?(Time.now)
          present checkout, with: CheckoutConfirmationEntity
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

  class FulfillmentOptionEntity < BaseEntity
    expose :id
    expose_translated :description
  end

  class CheckoutProductEntity < OfferingProductEntity
    expose :vendor, with: VendorEntity, &self.delegate_to(:product, :vendor)
  end

  class CheckoutItemEntity < BaseEntity
    expose :offering_product, as: :product, with: CheckoutProductEntity
    expose :quantity
  end

  class CheckoutEntity < BaseEntity
    expose :id
    expose :items, with: CheckoutItemEntity
    expose :offering, with: OfferingEntity, &self.delegate_to(:cart, :offering)
    expose :fulfillment_option_id
    expose :available_fulfillment_options, with: FulfillmentOptionEntity
    expose :payment_instrument, with: Suma::API::Entities::PaymentInstrumentEntity
    expose :available_payment_instruments, with: Suma::API::Entities::PaymentInstrumentEntity
    expose :save_payment_instrument

    expose :customer_cost, with: Suma::Service::Entities::Money
    expose :undiscounted_cost, with: Suma::Service::Entities::Money
    expose :savings, with: Suma::Service::Entities::Money
    expose :handling, with: Suma::Service::Entities::Money
    expose :taxable_cost, with: Suma::Service::Entities::Money
    expose :tax, with: Suma::Service::Entities::Money
    expose :total, with: Suma::Service::Entities::Money
  end

  class CheckoutConfirmationEntity < BaseEntity
    expose :id
    expose :items, with: CheckoutItemEntity
    expose :offering, with: OfferingEntity, &self.delegate_to(:cart, :offering)
    expose :fulfillment_option, with: FulfillmentOptionEntity
  end
end
