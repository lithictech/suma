# frozen_string_literal: true

require "rspec"
require "suma/spec_helpers/testing_helpers"

RSpec.shared_examples "a mobility trip provider" do
  include Suma::SpecHelpers::TestingHelpers

  let(:provider) { described_class.new }

  it "implements all abstract methods" do
    assert_implemented { provider.begin_trip(Suma::Fixtures.mobility_trip.instance) }
    assert_implemented { provider.end_trip(Suma::Fixtures.mobility_trip.instance) }
  end
end
