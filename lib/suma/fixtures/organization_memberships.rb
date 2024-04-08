# frozen_string_literal: true

require "suma"
require "suma/fixtures"
require "suma/organization/membership"

module Suma::Fixtures::OrganizationMemberships
  extend Suma::Fixtures

  fixtured_class Suma::Organization::Membership

  base :organization_membership do
  end

  before_saving do |instance|
    instance.organization ||= Suma::Fixtures.organization.create
    instance.member ||= Suma::Fixtures.member.create
    instance
  end
end
