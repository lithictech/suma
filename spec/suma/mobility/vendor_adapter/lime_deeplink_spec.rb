# frozen_string_literal: true

RSpec.describe Suma::Mobility::VendorAdapter::LimeDeeplink, :db do
  let(:instance) { described_class.new }
  let(:member) { Suma::Fixtures.member.onboarding_verified.create }
  let(:vendor_service) { Suma::Fixtures.vendor_service.mobility.create }

  it "returns the vendor account for the lime vendor, if one exists" do
    expect(instance.find_anon_proxy_vendor_account(member)).to be_nil
    vendor = Suma::Lime.mobility_vendor
    configuration = Suma::Fixtures.anon_proxy_vendor_configuration(vendor:).create
    expect(instance.find_anon_proxy_vendor_account(member)).to be_nil
    va = Suma::Fixtures.anon_proxy_vendor_account(configuration:, member:).create
    expect(instance.find_anon_proxy_vendor_account(member)).to be === va
  end
end
