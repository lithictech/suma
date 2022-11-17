# frozen_string_literal: true

require "suma/message/template"

class Suma::Messages::OrderConfirmation < Suma::Message::Template
  def self.fixtured(recipient)
    cart = Suma::Fixtures.cart(member: recipient).with_any_product.create
    co = Suma::Fixtures.checkout(cart:).populate_items.create
    order = Suma::Fixtures.order(checkout: co).create
    return self.new(order)
  end

  def initialize(order)
    @order = order
    super()
  end

  def template_name = @order.checkout.cart.offering.confirmation_template
  def template_folder = "offerings"

  def localized? = true
end
