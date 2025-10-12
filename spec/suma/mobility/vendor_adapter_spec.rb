# frozen_string_literal: true

require "suma/mobility/vendor_adapter"

RSpec.describe Suma::Mobility::VendorAdapter, :db do
  let(:instance) { described_class.new }
  let(:member) { Suma::Fixtures.member.onboarding_verified.create }
  let(:vendor_service) { Suma::Fixtures.vendor_service.create }
  let(:vendor) { vendor_service.vendor }

  describe "validations" do
    it "cannot use a trip provider key if using deep linking" do
      ad = Suma::Fixtures.mobility_vendor_adapter.instance
      expect do
        ad.update(trip_provider_key: "internal", uses_deep_linking: true)
      end.to raise_error(Sequel::ValidationFailed)

      expect do
        ad.update(trip_provider_key: "", uses_deep_linking: false)
      end.to raise_error(Sequel::ValidationFailed)
    end
  end

  describe "find_anon_proxy_vendor_account" do
    it "returns the vendor account for the lime vendor, if one exists" do
      ad = Suma::Fixtures.mobility_vendor_adapter.deeplink.create(vendor_service:)
      expect(ad.find_anon_proxy_vendor_account(member)).to be_nil
      configuration = Suma::Fixtures.anon_proxy_vendor_configuration(vendor:).create
      expect(ad.find_anon_proxy_vendor_account(member)).to be_nil
      va = Suma::Fixtures.anon_proxy_vendor_account(configuration:, member:).create
      expect(ad.find_anon_proxy_vendor_account(member)).to be === va
    end

    it "raises if not using deep linking" do
      ad = Suma::Fixtures.mobility_vendor_adapter.maas.create(vendor_service:)
      expect { ad.find_anon_proxy_vendor_account(member) }.to raise_error(Suma::AssertionError)
    end
  end

  describe "vendor_account_requires_attention" do
    let(:member) { Suma::Fixtures.member.create }

    it "is false if not using deep linking" do
      ad = Suma::Fixtures.mobility_vendor_adapter.maas.create(vendor_service:)
      expect(ad).to_not be_anon_proxy_vendor_account_requires_attention(member, now: Time.now)
    end

    describe "when using deep linking" do
      let(:ad) { Suma::Fixtures.mobility_vendor_adapter.deeplink.create(vendor_service:) }

      it "is true when there is no vendor account" do
        expect(ad).to be_anon_proxy_vendor_account_requires_attention(member, now: Time.now)
      end

      it "delegates to the vendor account configuration" do
        configuration = Suma::Fixtures.anon_proxy_vendor_configuration(vendor:).create
        va = Suma::Fixtures.anon_proxy_vendor_account(member:, configuration:).create
        expect(ad).to be_anon_proxy_vendor_account_requires_attention(member, now: Time.now)
        va.auth_to_vendor.auth
        expect(ad).to_not be_anon_proxy_vendor_account_requires_attention(member, now: Time.now)
      end
    end
  end
end
