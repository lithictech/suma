# frozen_string_literal: true

require "rspec"
require "suma/spec_helpers/testing_helpers"

RSpec.shared_examples "a mobility vendor adapter" do
  include Suma::SpecHelpers::TestingHelpers

  let(:adapter) { described_class.new }

  it "implements all abstract methods" do
    assert_implemented { adapter.begin_trip(Suma::Fixtures.mobility_trip.instance) }
    assert_implemented { adapter.end_trip(Suma::Fixtures.mobility_trip.instance) }
    assert_implemented { adapter.uses_deep_linking? }
    assert_implemented { adapter.send_receipts? }
    assert_implemented { adapter.find_anon_proxy_vendor_account(Suma::Fixtures.member.create) }
  end
end
