# frozen_string_literal: true

require "suma/fixtures"
require "suma/commerce/order"

module Suma::Fixtures::Orders
  extend Suma::Fixtures

  fixtured_class Suma::Commerce::Order

  base :order do
  end

  before_saving do |instance|
    instance.checkout ||= Suma::Fixtures.checkout.create
    instance
  end
end
