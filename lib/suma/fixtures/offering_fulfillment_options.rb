# frozen_string_literal: true

require "suma/fixtures"
require "suma/commerce/offering_fulfillment_option"

module Suma::Fixtures::OfferingFulfillmentOptions
  extend Suma::Fixtures

  fixtured_class Suma::Commerce::OfferingFulfillmentOption

  base :offering_fulfillment_option do
    self.type ||= "pickup"
  end

  before_saving do |instance|
    instance.description ||= Suma::Fixtures.translated_text(en: Faker::Address.community).create
    instance.offering ||= Suma::Fixtures.offering.create
    instance
  end
end
