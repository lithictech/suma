# frozen_string_literal: true

require "suma/fixtures"
require "suma/charge/line_item"

module Suma::Fixtures::ChargeLineItems
  extend Suma::Fixtures

  fixtured_class Suma::Charge::LineItem

  base :charge_line_item do
    self.amount_cents ||= Faker::Number.between(from: 100, to: 100_00)
    self.amount_currency ||= "USD"
  end

  before_saving do |instance|
    instance.charge ||= Suma::Fixtures.charge.create
    instance.memo ||= Suma::Fixtures.translated_text(all: Faker::Lorem.words(number: 3).join(" ")).create
    instance
  end
end
