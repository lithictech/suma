# frozen_string_literal: true

class Suma::Commerce::OfferingPicklist
  class OrderItem
    attr_reader :id, :quantity, :serial, :member, :offering_product, :fulfillment_option, :status

    def initialize(checkout_item)
      @id = checkout_item.id
      @quantity = checkout_item.quantity
      @serial = checkout_item.checkout.order.serial
      @member = checkout_item.checkout.cart.member
      @offering_product = checkout_item.offering_product
      @fulfillment_option = checkout_item.checkout.fulfillment_option
      @status = checkout_item.checkout.order.fulfillment_status
    end
  end

  attr_reader :offering, :products_and_quantities, :fulfillment_options_and_quantities, :order_items

  def initialize(offering)
    @offering = offering
    @order_items = []
  end

  def build
    orders = @offering.orders_dataset.uncanceled.all
    checkout_items = orders.map { |o| o.checkout.items }.flatten
    checkout_items.each do |ci|
      oi = OrderItem.new(ci)
      @order_items << oi
    end
    return self
  end
end
