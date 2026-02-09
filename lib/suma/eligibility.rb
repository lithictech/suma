# frozen_string_literal: true

module Suma::Eligibility
  # True if resources types (programs, payment triggers) should be available to everyone
  # when they have no eligibility requirements (value of +true+),
  # or available to no one until they have a valid requirement (value of +false+).
  #
  # This value is +true+ when running tests, because otherwise we need to
  # create an entire eligibility tree for every  fixtured resource to member being tested.
  #
  # Since eligibility is designed to be orthogonal to the components they're providing access to,
  # this makes tests and concepts messy. But it's a safer default outside of tests.
  RESOURCES_DEFAULT_ACCESSIBLE = Suma.test?
end

require "suma/eligibility/evaluation"
require "suma/eligibility/resource"
require "sequel/identity_set"
