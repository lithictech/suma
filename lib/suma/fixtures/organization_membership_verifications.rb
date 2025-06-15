# frozen_string_literal: true

require "suma/fixtures"
require "suma/organization/membership/verification"

module Suma::Fixtures::OrganizationMembershipVerifications
  extend Suma::Fixtures

  fixtured_class Suma::Organization::Membership::Verification

  base :organization_membership_verification do
  end

  before_saving do |instance|
    instance.membership ||= Suma::Fixtures.organization_membership.unverified.create
    instance
  end

  decorator :member do |member={}|
    member = Suma::Fixtures.member.create(member) unless member.is_a?(Suma::Member)
    self.membership ||= Suma::Fixtures.organization_membership.unverified.create(member:)
    self.membership.update(member:)
  end

  decorator :organization do |organization={}|
    organization = Suma::Fixtures.organization.create(organization) unless organization.is_a?(Suma::Organization)
    self.membership ||= Suma::Fixtures.organization_membership.unverified.create(organization:)
    self.membership.update(organization:)
  end
end
