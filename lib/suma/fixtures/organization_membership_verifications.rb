# frozen_string_literal: true

require "suma/fixtures"
require "suma/organization/membership_verification"

module Suma::Fixtures::OrganizationMembershipVerifications
  extend Suma::Fixtures

  fixtured_class Suma::Organization::MembershipVerification

  base :organization_membership_verification do
  end

  before_saving do |instance|
    instance.membership ||= Suma::Fixtures.organization_membership.unverified.create
    instance
  end
end
