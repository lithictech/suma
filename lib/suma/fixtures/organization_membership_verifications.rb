# frozen_string_literal: true

require "suma/fixtures"
require "suma/organization/membership/verification"

module Suma::Fixtures::OrganizationMembershipVerifications
  extend Suma::Fixtures

  fixtured_class Suma::Organization::Membership::Verification

  def self.create_unassociated_membership(fac)
    Suma::Organization::Membership.disable_auto_verification_creation = true
    return fac.create
  ensure
    Suma::Organization::Membership.disable_auto_verification_creation = false
  end

  base :organization_membership_verification do
  end

  before_saving do |instance|
    instance.membership ||= Suma::Fixtures::OrganizationMembershipVerifications.create_unassociated_membership(
      Suma::Fixtures.organization_membership.unverified,
    )
    instance
  end

  decorator :member do |member={}|
    member = Suma::Fixtures.member.create(member) unless member.is_a?(Suma::Member)
    self.membership ||= Suma::Fixtures::OrganizationMembershipVerifications.create_unassociated_membership(
      Suma::Fixtures.organization_membership(member:).unverified,
    )
    self.membership.update(member:)
  end

  decorator :organization do |organization={}|
    organization = Suma::Fixtures.organization.create(organization) unless organization.is_a?(Suma::Organization)
    self.membership = Suma::Fixtures::OrganizationMembershipVerifications.create_unassociated_membership(
      Suma::Fixtures.organization_membership.unverified(organization.name),
    )
  end

  decorator :able_to_verify do
    org = Suma::Fixtures.organization.create
    self.membership = Suma::Fixtures::OrganizationMembershipVerifications.create_unassociated_membership(
      Suma::Fixtures.organization_membership.unverified(org.name),
    )
  end
end
