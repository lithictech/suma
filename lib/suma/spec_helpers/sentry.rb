# frozen_string_literal: true

require "suma/spec_helpers"

require_relative "testing_helpers"

module Suma::SpecHelpers::Sentry
  include Suma::SpecHelpers::TestingHelpers

  module_function def expect_sentry_capture(type: :exception, arg_matcher: nil, scope_matcher: nil)
    expect(Sentry).to receive(:"capture_#{type}") do |arg, &block|
      reraise_as_mock_expectation { expect(arg).to(arg_matcher) if arg_matcher }
      scope = Sentry::Scope.new
      block.call(scope) if block
      reraise_as_mock_expectation { expect(scope).to(scope_matcher) if scope_matcher }
    end
  end
end
