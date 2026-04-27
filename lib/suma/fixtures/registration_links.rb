# frozen_string_literal: true

require "suma/fixtures"
require "suma/organization/registration_link"

module Suma::Fixtures::RegistrationLinks
  extend Suma::Fixtures

  fixtured_class Suma::Organization::RegistrationLink

  base :registration_link do
  end

  before_saving do |instance|
    instance.organization ||= Suma::Fixtures.organization.create
    instance
  end
end
