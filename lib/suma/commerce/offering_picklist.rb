# frozen_string_literal: true

class Suma::Commerce::OfferingPicklist
  class ProductAndQuantity
    attr_reader :product, :quantity

    def initialize(product, quantity)
      @product = product
      @quantity = quantity
    end
  end

  class FulfillmentOptionAndQuantity
    attr_reader :fulfillment_option, :quantity

    def initialize(opt, quantity)
      @fulfillment_option = opt
      @quantity = quantity
    end
  end

  class OrderItem
    attr_reader :id, :quantity, :serial, :member, :offering_product, :fulfillment_option

    def initialize(checkout_item)
      @id = checkout_item.id
      @quantity = checkout_item.quantity
      @serial = checkout_item.checkout.order.serial
      @member = checkout_item.checkout.cart.member
      @offering_product = checkout_item.offering_product
      @fulfillment_option = checkout_item.checkout.fulfillment_option
    end
  end

  attr_reader :offering, :products_and_quantities, :fulfillment_options_and_quantities, :order_items

  def initialize(offering)
    @offering = offering
    @order_items = []
    @products_for_ids = {}
    @fulfillment_options_for_ids = {}
    @quantities_for_products = Hash.new(0)
    @quantities_for_fulfillments = Hash.new(0)
  end

  def build
    orders = @offering.orders_dataset.uncanceled.all
    checkout_items = orders.map { |o| o.checkout.items }.flatten
    checkout_items.each do |ci|
      oi = OrderItem.new(ci)
      @order_items << oi
      @products_for_ids[oi.offering_product.product_id] ||= oi.offering_product.product
      @fulfillment_options_for_ids[oi.fulfillment_option.id] ||= oi.fulfillment_option
      @quantities_for_products[oi.offering_product.product_id] += oi.quantity
      @quantities_for_fulfillments[oi.fulfillment_option.id] += oi.quantity
    end
    @products_and_quantities = @products_for_ids.values.map do |pr|
      ProductAndQuantity.new(pr, @quantities_for_products[pr.id])
    end
    @fulfillment_options_and_quantities = @fulfillment_options_for_ids.values.map do |fo|
      FulfillmentOptionAndQuantity.new(fo, @quantities_for_fulfillments[fo.id])
    end
    return self
  end
end
