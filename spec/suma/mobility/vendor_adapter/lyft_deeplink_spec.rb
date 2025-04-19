# frozen_string_literal: true

RSpec.describe Suma::Mobility::VendorAdapter::LyftDeeplink, :db, reset_configuration: Suma::Lyft do
  let(:instance) { described_class.new }
  let(:member) { Suma::Fixtures.member.onboarding_verified.create }
  let(:vendor_service) { Suma::Fixtures.vendor_service.mobility.create }
  let(:vendor) { vendor_service.vendor }

  it "returns the vendor account for the lyft vendor, if one exists" do
    Suma::Lyft.deeplink_vendor_slug = vendor.slug
    expect(instance.find_anon_proxy_vendor_account(member)).to be_nil
    configuration = Suma::Fixtures.anon_proxy_vendor_configuration(vendor:).create
    expect(instance.find_anon_proxy_vendor_account(member)).to be_nil
    va = Suma::Fixtures.anon_proxy_vendor_account(configuration:, member:).create
    expect(instance.find_anon_proxy_vendor_account(member)).to be === va
  end
end
