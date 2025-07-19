# frozen_string_literal: true

require "suma/message/template"

class Suma::Messages::OrderConfirmation < Suma::Message::Template
  def self.fixtured(recipient)
    cart = Suma::Fixtures.cart(member: recipient).with_any_product.create
    cart.offering.update(confirmation_template: "testoffer")
    co = Suma::Fixtures.checkout(cart:).populate_items.create
    order = Suma::Fixtures.order(checkout: co).create
    tmpl = self.new(order)
    Suma::Fixtures.static_string.
      message(tmpl, "sms").
      text("test confirmation (en)", es: "test confirmation (es)").
      create
    return tmpl
  end

  def initialize(order)
    @order = order
    super()
  end

  def template_name = @order.checkout.cart.offering.confirmation_template
  def template_folder = "offerings"

  def localized? = true
end
