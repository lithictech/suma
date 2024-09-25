# frozen_string_literal: true

require "suma"
require "suma/fixtures"

module Suma::Fixtures::LegalEntities
  extend Suma::Fixtures

  fixtured_class Suma::LegalEntity

  base :legal_entity do
    self.name ||= Faker::Name.name
  end

  before_saving do |instance|
    instance
  end

  decorator :with_contact_info do |o={}|
    o[:name] ||= Faker::Name.name
    self.set(**o)
  end

  decorator :with_address do |a={}|
    a = Suma::Fixtures.address(a).create unless a.is_a?(Suma::Address)
    self.address = a
  end
end
