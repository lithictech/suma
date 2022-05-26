# frozen_string_literal: true

require "suma/fixtures"
require "suma/supported_geography"

module Suma::Fixtures::SupportedGeographies
  extend Suma::Fixtures

  fixtured_class Suma::SupportedGeography

  base :supported_geography do
    self.value ||= Faker::Address.state
    self.label ||= self.value
    self.type ||= "province"
  end

  decorator :state do |value=Faker::Address.state, label=nil|
    raise "Must set country before state" if self.parent_id.nil?
    self.value = value
    self.label = label || value
    self.type = "province"
  end

  decorator :in_country do |value=Faker::Address.country, label=nil|
    self.parent = Suma::SupportedGeography.find_or_create(value:, label: label || value, type: "country")
  end

  decorator :in_usa do
    self.parent = Suma::SupportedGeography.find_or_create(
      value: "United States of America", label: "USA", type: "country",
    )
  end
end
