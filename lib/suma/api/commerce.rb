# frozen_string_literal: true

require "grape"
require "suma/api"
require "suma/service/entities"

class Suma::API::Commerce < Suma::API::V1
  include Suma::Service::Types
  include Suma::API::Entities

  resource :commerce do
    helpers do
      def new_context
        return Suma::Payment::CalculationContext.new(current_time)
      end

      def set_fulfillment_or_error(checkout, option_id, options)
        allow_nil = checkout.fulfillment_option.nil? && option_id.nil?
        valid_option = allow_nil || options.any? { |o| o.id == option_id }
        invalid!("Not a valid fulfillment option") unless valid_option
        checkout.set(fulfillment_option_id: option_id)
      end
    end

    resource :offerings do
      desc "Return all commerce offerings that are not closed"
      get do
        me = current_member
        ds = Suma::Commerce::Offering.available_at(current_time).eligible_to(me, as_of: current_time)
        present_collection ds, with: OfferingEntity
      end

      route_param :offering_id, type: Integer do
        helpers do
          def lookup_offering!(t)
            (offering = Suma::Commerce::Offering[params[:offering_id]]) or forbidden!
            forbidden! unless offering.available_at?(t)
            check_eligibility!(offering, current_member)
            return offering
          end

          def lookup_cart!(offering)
            return Suma::Commerce::Cart.lookup(member: current_member, offering:)
          end

          def present_offering(offering)
            items = offering.offering_products_dataset.available.all
            cart = lookup_cart!(offering)
            vendors = items.map { |v| v.product.vendor }.uniq(&:id)
            present offering, with: OfferingWithContextEntity, cart:, items:, vendors:, context: new_context
          end
        end

        # Return offering and product info.
        # If we need paginated offering items, we can add an endpoint that just returns
        # paginated items after the first page.
        get do
          current_member
          offering = lookup_offering!(current_time)
          present_offering(offering)
        end

        resource :cart do
          params do
            requires :product_id, type: Integer
            requires :quantity, type: Integer
            optional :timestamp, type: Float, allow_blank: true
          end
          put :item do
            offering = lookup_offering!(current_time)
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
            present_offering(offering)
          end
        end

        post :checkout do
          offering = lookup_offering!(current_time)
          cart = lookup_cart!(offering)
          ctx = new_context
          begin
            checkout = cart.create_checkout(ctx)
          rescue Suma::Commerce::Cart::EmptyCart
            merror!(409, "no items in cart", code: "checkout_no_items")
          rescue Suma::Commerce::Cart::ProductUnavailable
            merror!(409, "product unavailable", code: "invalid_order_quantity")
          rescue Suma::Commerce::Checkout::MaxQuantityExceeded
            merror!(409, "max quantity exceeded", code: "invalid_order_quantity")
          end
          status 200
          present checkout, with: CheckoutEntity, cart:, context: ctx
        end
      end
    end

    resource :checkouts do
      route_param :id, type: Integer do
        helpers do
          def lookup!
            (ch = Suma::Commerce::Checkout[params[:id]]) or forbidden!
            forbidden! unless ch.cart.member === current_member
            forbidden! if ch.items.empty? # This can happen when cart items are cleared after checkout starts
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
          present checkout, with: CheckoutEntity, cart: checkout.cart, context: new_context
        end

        params do
          requires :option_id, type: Integer
        end
        post :modify_fulfillment do
          checkout = lookup_editable!
          set_fulfillment_or_error(checkout, params[:option_id], checkout.available_fulfillment_options)
          checkout.save_changes
          status 200
          present checkout, with: CheckoutEntity, cart: checkout.cart, context: new_context
        end

        params do
          requires :charge_amount_cents, type: Integer
          optional :payment_instrument, type: JSON do
            use :payment_instrument
          end
          optional :fulfillment_option_id, type: Integer
          optional :save_payment_instrument, type: Boolean, allow_blank: false
        end
        post :complete do
          member = current_member
          checkout = lookup!
          check_eligibility!(checkout.cart.offering, member)
          if checkout.cost_info(at: current_time).requires_payment_instrument?
            instrument = find_payment_instrument?(member, params[:payment_instrument])
            checkout.payment_instrument = instrument if instrument
          end

          if params.key?(:fulfillment_option_id)
            set_fulfillment_or_error(checkout, params[:fulfillment_option_id], checkout.available_fulfillment_options)
          end

          checkout.save_payment_instrument = params[:save_payment_instrument] if
            params.key?(:save_payment_instrument)

          checkout.db.transaction do
            checkout.save_changes
            begin
              checkout.create_order(apply_at: current_time, cash_charge_amount: Money.new(params[:charge_amount_cents]))
            rescue Suma::Commerce::Checkout::Prohibited => e
              merror!(409, "Checkout prohibited: #{e.reason}", code: "checkout_fatal_error")
            rescue Suma::Commerce::Checkout::MaxQuantityExceeded
              merror!(403, "max quantity exceeded", code: "invalid_order_quantity")
            end
          end
          add_current_member_header
          status 200
          present checkout, with: CheckoutConfirmationEntity, cart: checkout.cart
        end

        get :confirmation do
          checkout = lookup!
          forbidden! unless checkout.completed?
          forbidden! unless checkout.expose_for_confirmation?(current_time)
          present checkout, with: CheckoutConfirmationEntity, cart: checkout.cart
        end
      end
    end

    resource :orders do
      get do
        me = current_member
        ds = me.orders_dataset
        ds = ds.order(Sequel.desc(:created_at), :id)
        present_collection ds, with: OrderHistoryCollection, detailed_orders: ds.first(2)
      end

      get :unclaimed do
        me = current_member
        ds = me.orders_dataset.available_to_claim
        ds = ds.order(Sequel.desc(:created_at), :id)
        present_collection ds, with: UnclaimedOrderCollection
      end

      route_param :id, type: Integer do
        helpers do
          def lookup
            me = current_member
            (o = me.orders_dataset[params[:id]]) or forbidden!
            return o
          end
        end
        get do
          order = lookup
          present order, with: DetailedOrderHistoryEntity
        end

        params do
          requires :option_id, type: Integer
        end
        post :modify_fulfillment do
          order = lookup
          set_fulfillment_or_error(
            order.checkout,
            params[:option_id],
            order.fulfillment_options_for_editing,
          )
          order.checkout.save_changes
          status 200
          present order, with: DetailedOrderHistoryEntity
        end

        post :claim do
          order = lookup
          order.db.transaction do
            merror!(409, "Order cannot be claimed", code: "invalid_permissions") unless order.process(:claim)
          end
          add_current_member_header
          status 200
          present order, with: DetailedOrderHistoryEntity
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
    expose :cart_hash
    expose :items, with: CartItemEntity
    expose :customer_cost, with: Suma::Service::Entities::Money
    expose :noncash_ledger_contribution_amount, with: Suma::Service::Entities::Money do |inst, opts|
      inst.cost_info(opts.fetch(:context)).noncash_ledger_contribution_amount
    end
    expose :cash_cost, with: Suma::Service::Entities::Money do |inst, opts|
      inst.cost_info(opts.fetch(:context)).cash_cost
    end
    expose :cart_full?, as: :cart_full
  end

  class OfferingEntity < BaseEntity
    expose :id
    expose_translated :description
    expose_translated :fulfillment_prompt
    expose_translated :fulfillment_confirmation
    expose_translated :fulfillment_instructions
    expose :period_end_visible, as: :closes_at
    expose :image, with: Suma::API::Entities::ImageEntity, &self.delegate_to(:images?, :first)
    expose :rel_app_link, as: :app_link
  end

  class BaseOfferingProductEntity < BaseEntity
    expose_translated :name, &self.delegate_to(:product, :name)
    expose_translated :description, &self.delegate_to(:product, :description)
    expose :offering_id
    expose :product_id, &self.delegate_to(:product, :id)
    expose :vendor, with: VendorEntity, &self.delegate_to(:product, :vendor)
    expose :images, with: Suma::API::Entities::ImageEntity, &self.delegate_to(:product, :images?)
  end

  class PricedOfferingProductEntity < BaseOfferingProductEntity
    expose :max_quantity
    expose :out_of_stock do |_|
      self.max_quantity <= 0
    end

    expose :displayable_noncash_ledger_contribution_amount, with: Suma::Service::Entities::Money do |_inst|
      self.noncash_ledger_contrib
    end
    expose :displayable_cash_price, with: Suma::Service::Entities::Money do |inst|
      noncash = self.noncash_ledger_contrib
      inst.customer_price - noncash
    end

    expose :is_discounted, &self.delegate_to(:discounted?, safe_with_default: false)
    expose :customer_price,
           with: Suma::Service::Entities::Money,
           &self.delegate_to(:customer_price, safe_with_default: Money.new(0))
    expose :undiscounted_price,
           with: Suma::Service::Entities::Money,
           &self.delegate_to(:undiscounted_price, safe_with_default: Money.new(0))
    expose :discount_amount,
           with: Suma::Service::Entities::Money,
           &self.delegate_to(:discount_amount, safe_with_default: Money.new(0))

    private def max_quantity
      return @max_quantity ||= self.options.fetch(:cart).max_quantity_for(self.object)
    end

    private def noncash_ledger_contrib
      return @noncash_ledger_contrib ||= self.options.fetch(:cart).
          cost_info(self.options.fetch(:context)).
          product_noncash_ledger_contribution_amount(self.object)
    end
  end

  class OfferingWithContextEntity < BaseEntity
    expose :offering, with: OfferingEntity do |instance|
      instance
    end
    expose :items, with: PricedOfferingProductEntity do |_, opts|
      opts.fetch(:items)
    end
    expose :vendors, with: VendorEntity do |_, opts|
      opts.fetch(:vendors)
    end
    expose :cart, with: CartEntity do |_, opts|
      opts.fetch(:cart)
    end
  end

  class FulfillmentOptionAddressEntity < BaseEntity
    expose :one_line_address, &self.delegate_to(:one_line_address)
  end

  class FulfillmentOptionEntity < BaseEntity
    include Suma::API::Entities
    expose :id
    expose_translated :description
    expose :address, with: FulfillmentOptionAddressEntity
  end

  class CheckoutProductEntity < PricedOfferingProductEntity
    expose :vendor, with: VendorEntity, &self.delegate_to(:product, :vendor)
  end

  class CheckoutItemEntity < BaseEntity
    expose :offering_product, as: :product, with: CheckoutProductEntity
    expose :quantity
  end

  class ChargeContributionEntity < BaseEntity
    expose :amount, with: Suma::Service::Entities::Money
    expose :name, &self.delegate_to(:ledger, :contribution_text, :string)
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
    expose :chargeable_total, with: Suma::Service::Entities::Money do |_object|
      self.cost_info.chargeable_total
    end
    expose :requires_payment_instrument do |_object|
      self.cost_info.requires_payment_instrument?
    end
    expose :checkout_prohibited_reason do |_object|
      self.cost_info.checkout_prohibited_reason
    end
    expose :existing_funds_available, with: ChargeContributionEntity do |_object|
      self.cost_info.existing_funds_available
    end

    private def cost_info
      return @cost_info ||= self.object.cost_info(at: self.options.fetch(:context).apply_at)
    end
  end

  # CheckoutItemEntity and CheckoutProductEntity need cost info,
  # which confirmations do not.
  class CheckoutConfirmationProductEntity < BaseOfferingProductEntity
    expose :vendor, with: VendorEntity, &self.delegate_to(:product, :vendor)
  end

  class CheckoutConfirmationItemEntity < BaseEntity
    expose :offering_product, as: :product, with: CheckoutConfirmationProductEntity
    expose :quantity
  end

  class CheckoutConfirmationEntity < BaseEntity
    expose :id
    expose :items, with: CheckoutConfirmationItemEntity
    expose :offering, with: OfferingEntity, &self.delegate_to(:cart, :offering)
    expose :fulfillment_option, with: FulfillmentOptionEntity
  end

  class SimpleOrderHistoryEntity < BaseEntity
    include Suma::API::Entities
    expose :id
    expose :serial
    expose :created_at
    expose :fulfilled_at
    expose :total, with: MoneyEntity, &self.delegate_to(:checkout, :total)
    expose :image, with: ImageEntity do |inst|
      inst.checkout.items.sample&.offering_product&.product&.images&.first
    end
    expose :available_for_pickup_at, &self.delegate_to(:checkout, :cart, :offering, :begin_fulfillment_at)
  end

  class OrderHistoryFundingTransactionEntity < BaseEntity
    include Suma::API::Entities
    expose :amount, with: MoneyEntity
    expose :label, &self.delegate_to(:strategy, :originating_instrument, :simple_label)
  end

  class OrderHistoryItemEntity < BaseEntity
    include Suma::API::Entities
    expose :quantity
    expose_translated :name, &self.delegate_to(:offering_product, :product, :name)
    expose_translated :description, &self.delegate_to(:offering_product, :product, :description)
    expose :image, with: ImageEntity, &self.delegate_to(:offering_product, :product, :images?, :first)
    expose :customer_price, with: MoneyEntity, &self.delegate_to(:offering_product, :customer_price)
  end

  class DetailedOrderHistoryEntity < SimpleOrderHistoryEntity
    include Suma::API::Entities
    expose :items, with: OrderHistoryItemEntity, &self.delegate_to(:checkout, :items)
    expose :offering_id, &self.delegate_to(:checkout, :cart, :offering_id)
    expose_translated :offering_description, &self.delegate_to(:checkout, :cart, :offering, :description)
    expose_translated :fulfillment_confirmation,
                      &self.delegate_to(:checkout, :cart, :offering, :fulfillment_confirmation)
    expose :fulfillment_option, with: FulfillmentOptionEntity, &self.delegate_to(:checkout, :fulfillment_option)
    expose :fulfillment_options_for_editing, with: FulfillmentOptionEntity
    expose :fulfillment_option_editable?, as: :fulfillment_option_editable

    expose :order_status
    expose :can_claim?, as: :can_claim

    expose :customer_cost, with: MoneyEntity, &self.delegate_to(:checkout, :customer_cost)
    expose :undiscounted_cost, with: MoneyEntity, &self.delegate_to(:checkout, :undiscounted_cost)
    expose :savings, with: MoneyEntity, &self.delegate_to(:checkout, :savings)
    expose :handling, with: MoneyEntity, &self.delegate_to(:checkout, :handling)
    expose :taxable_cost, with: MoneyEntity, &self.delegate_to(:checkout, :taxable_cost)
    expose :tax, with: MoneyEntity, &self.delegate_to(:checkout, :tax)
    expose :funded_amount, with: MoneyEntity
    expose :paid_amount, with: MoneyEntity
    expose :funding_transactions, with: OrderHistoryFundingTransactionEntity do |inst|
      inst.charges.map(&:associated_funding_transactions).flatten
    end
  end

  # We can assume the user is going to most often view their very recent history,
  # so provide them to the frontend to avoid extra API calls.
  class OrderHistoryCollection < Suma::Service::Collection::BaseEntity
    expose :items, with: SimpleOrderHistoryEntity
    expose :detailed_orders, with: DetailedOrderHistoryEntity do |_, opts|
      opts.fetch(:detailed_orders)
    end
  end

  class UnclaimedOrderCollection < Suma::Service::Collection::BaseEntity
    # This should be a relatively small list, so always return the detailed orders.
    expose :items, with: DetailedOrderHistoryEntity
  end
end
