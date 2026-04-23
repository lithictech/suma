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
