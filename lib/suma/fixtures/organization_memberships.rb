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
    raise "must call .verified or .unverified" if instance.member.nil?
    instance
  end

  decorator :verified do |o={}|
    o = Suma::Fixtures.member(o).create unless o.is_a?(Suma::Member)
    self.verified_member = o
  end

  decorator :unverified do |o={}|
    o = Suma::Fixtures.member(o).create unless o.is_a?(Suma::Member)
    self.unverified_member = o
  end
end
