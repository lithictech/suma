# frozen_string_literal: true

require "suma"
require "suma/fixtures"
require "suma/organization/membership"

module Suma::Fixtures::OrganizationMemberships
  extend Suma::Fixtures

  fixtured_class Suma::Organization::Membership

  class << self
    def ensure_fixturable(factory) = super.unverified
  end

  base :organization_membership do
  end

  before_saving do |instance|
    instance.member ||= Suma::Fixtures.member.create
    raise "must call .verified or .unverified" if
      instance.verified_organization.nil? &&
        instance.unverified_organization_name.nil? &&
        instance.former_organization.nil?
    instance
  end

  decorator :verified do |org={}|
    org = Suma::Fixtures.organization(org).create unless org.is_a?(Suma::Organization)
    self.verified_organization = org
  end

  decorator :unverified do |name=Faker::Company.name|
    self.unverified_organization_name = name
  end

  decorator :former do |org={}|
    org = Suma::Fixtures.organization(org).create unless org.is_a?(Suma::Organization)
    self.former_organization = org
    self.formerly_in_organization_at = Time.now
  end
end
