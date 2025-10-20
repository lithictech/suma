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

  # Run the RSpec mock verification code that would normally come at the end of an example.
  # Needed for testing helpers that set up mocks.
  def flush_mocks
    RSpec::Mocks.space.verify_all
  ensure
    RSpec::Mocks.space.reset_all
  end

  # Same as 'expect', but always flushes mocks after the block is called.
  # Helpful because sometimes a capture will or won't raise due to a mock match,
  # so this ensures mocks are always flushed.
  def expect_mocking(&)
    return expect do
      yield
    ensure
      flush_mocks
    end
  end

  # Like fail_with, but use rspec mocks exception type.
  def fail_mocks_with(msg, &)
    return RSpec::Matchers::BuiltIn::RaiseError.new(RSpec::Mocks::MockExpectationError, msg, &)
  end

  # Reraise expectation failures as mock expectation failures, so fail_mocks_with works right
  # and we get more consistent behavior.
  def reraise_as_mock_expectation(&)
    yield
  rescue RSpec::Expectations::ExpectationNotMetError => e
    raise RSpec::Mocks::MockExpectationError, e.message
  end
end
