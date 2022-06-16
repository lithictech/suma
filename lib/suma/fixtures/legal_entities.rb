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
    o[:contact_first_name] ||= Faker::Name.first_name
    o[:contact_first_name] ||= Faker::Name.first_name
    o[:contact_last_name] ||= Faker::Name.last_name
    o[:company_name] ||= Faker::Company.name
    o[:email] ||= Faker::Internet.email
    o[:phone] ||= Faker.us_phone
    o[:type] ||= "TEST"
    self.set(**o)
  end

  decorator :linked_to, presave: true do |member|
    member.add_linked_legal_entity(self)
  end

  decorator :with_address do |a={}|
    a = Suma::Fixtures.address(a).create unless a.is_a?(Suma::Address)
    self.address = a
  end
end
