# frozen_string_literal: true

require "suma/async"
require "suma/spec_helpers"

module Suma::SpecHelpers::TestingHelpers
  def assert_implemented
    # Go the long way around to avoid the rspect warning of on_potential_false_positives
    yield
  rescue WebMock::NetConnectNotAllowedError
    # We expect we'll hit these at times because we aren't doing faking for these behavior tests.
    nil
  rescue StandardError => e
    # NotImplementedError are not StandardError so will bubble up.
    # This should not happen, as it's a programming error.
    raise e if e.inspect.include?("ArgumentError: wrong number of arguments")
    # Other errors are probably ok to ignore.
  end
end
