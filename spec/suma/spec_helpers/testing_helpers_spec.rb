# frozen_string_literal: true

require "suma/spec_helpers/testing_helpers"

RSpec.describe Suma::SpecHelpers::TestingHelpers do
  include Suma::SpecHelpers::TestingHelpers

  describe "assert_implemented" do
    include Suma::SpecHelpers::TestingHelpers

    def foo(_x) = nil

    it "raises for NotImplemented and Argument errors" do
      assert_implemented { 1 }
      assert_implemented { HTTParty.get("/") }
      assert_implemented { 1 / 0 }
      assert_implemented { raise "hi" }

      expect do
        # noinspection RubyArgCount
        assert_implemented { foo(1, 2) }
      end.to raise_error(ArgumentError)

      expect do
        assert_implemented { raise NotImplementedError }
      end.to raise_error(NotImplementedError)
    end
  end
end
