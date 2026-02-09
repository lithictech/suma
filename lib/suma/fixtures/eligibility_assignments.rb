# frozen_string_literal: true

require "suma/fixtures"

module Suma::Fixtures::EligibilityAssignments
  extend Suma::Fixtures

  fixtured_class Suma::Eligibility::Assignment

  base :eligibility_assignment do
  end

  before_saving do |instance|
    instance.attribute ||= Suma::Fixtures.eligibility_attribute.create
    instance.assignee ||= Suma::Fixtures.send([:member, :organization, :role].sample).create
    instance
  end

  decorator :of do |attr={}|
    attr = Suma::Fixtures.eligibility_attribute.create(attr) unless attr.is_a?(Suma::Eligibility::Attribute)
    self.attribute = attr
  end

  decorator :to do |o|
    self.assignee = o
  end
end
