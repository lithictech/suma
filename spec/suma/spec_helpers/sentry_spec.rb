# frozen_string_literal: true

require "suma/spec_helpers/sentry"
require "suma/spec_helpers/testing_helpers"

RSpec.describe Suma::SpecHelpers::Sentry do
  include Suma::SpecHelpers::Sentry
  include Suma::SpecHelpers::TestingHelpers

  describe "passes" do
    [
      ["naked exception capture", -> { {type: :exception} }],
      ["exception arg matcher", -> { {type: :exception, arg_matcher: be_a(KeyError)} }],
      ["scope matcher", -> { {scope_matcher: have_attributes(level: :info)} }],
    ].each do |(name, arg_builder)|
      it name do
        args = instance_exec(&arg_builder)
        expect_sentry_capture(**args)
        Sentry.capture_exception(KeyError.new("some-err")) do |scope|
          scope.set_level :info
        end
      end
    end

    [
      ["naked message capture", -> { {type: :message} }],
      ["message arg matcher", -> { {type: :message, arg_matcher: start_with("hello")} }],
    ].each do |(name, arg_builder)|
      it name do
        args = instance_exec(&arg_builder)
        expect_sentry_capture(**args)
        Sentry.capture_message("hello world")
      end
    end
  end

  describe "failure messages" do
    it "fails if nothing called" do
      expect_sentry_capture
      expect do
        flush_mocks
      end.to fail_mocks_with(include("received: 0 times with any arguments"))
    end

    it "fails when called type does not match" do
      expect_sentry_capture(type: :exception)
      expect_mocking do
        Sentry.capture_message("exception message")
      end.to fail_mocks_with(include("expected: 1 time with any arguments"))
    end

    it "fails with wrong arg matcher" do
      expect_sentry_capture(arg_matcher: be_a(ArgumentError))
      expect_mocking do
        Sentry.capture_exception(KeyError.new("some-err"))
      end.to fail_mocks_with(include("expected #<KeyError: some-err> to be a kind of ArgumentError"))
    end

    it "fails with wrong scope matcher" do
      expect_sentry_capture(type: :message, scope_matcher: have_attributes(level: :info))
      expect_mocking do
        Sentry.capture_message("hi") do |scope|
          scope.set_level :debug
        end
      end.to fail_mocks_with(include("to have attributes {:level => :info} but had attributes {:level => :debug}"))
    end
  end
end
