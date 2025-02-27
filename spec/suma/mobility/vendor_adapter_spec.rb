# frozen_string_literal: true

require "suma/mobility/vendor_adapter"

RSpec.describe Suma::Mobility::VendorAdapter, :db do
  before(:each) do
    Suma::Mobility::VendorAdapter::Fake.reset
  end

  describe "registry" do
    it "returns a registered adapter" do
      expect(described_class.create(:fake)).to be_a(Suma::Mobility::VendorAdapter::Fake)
      expect(described_class.create("fake")).to be_a(Suma::Mobility::VendorAdapter::Fake)
    end

    it "raises for an unknown adapter" do
      expect do
        described_class.create(:blah)
      end.to raise_error(Suma::SimpleRegistry::Unregistered)
    end
  end

  describe "Fake" do
    let(:ad) { Suma::Mobility::VendorAdapter::Fake.new }

    it "can start and stop" do
      trip = Suma::Mobility::Trip.new
      expect(ad.begin_trip(trip)).to be_a(described_class::BeginTripResult)
      expect(trip).to have_attributes(external_trip_id: be_present)
      trip = Suma::Fixtures.mobility_trip.ongoing.create
      expect(ad.end_trip(trip)).to be_a(described_class::EndTripResult)
    end

    it "returns the charge based on the rate" do
      rate = Suma::Fixtures.vendor_service_rate.surcharge(100).unit_amount(20).create
      trip = Suma::Fixtures.mobility_trip.create(began_at: 5.minutes.ago, vendor_service_rate: rate)
      endres = ad.end_trip(trip)
      expect(endres).to have_attributes(
        cost_cents: 200,
        cost_currency: "USD",
        duration_minutes: 5,
      )
    end
  end

  describe "vendor_account_requires_attention" do
    let(:member) { Suma::Fixtures.member.create }
    let(:ad) { Suma::Mobility::VendorAdapter::Fake.new }

    it "is false if not using deep linking" do
      expect(ad).to_not be_anon_proxy_vendor_account_requires_attention(member)
    end

    describe "when using deep linking" do
      before(:each) do
        Suma::Mobility::VendorAdapter::Fake.uses_deep_linking = true
      end

      it "is true when there is no vendor account" do
        expect(ad).to be_anon_proxy_vendor_account_requires_attention(member)
      end

      describe "when the vendor config requires an anonymous address (private account)" do
        let(:va) { Suma::Fixtures.anon_proxy_vendor_account(member:).with_configuration(uses_sms: true).create }

        it "is true when the account is missing an address" do
          Suma::Mobility::VendorAdapter::Fake.find_anon_proxy_vendor_account_results << va
          expect(ad).to be_anon_proxy_vendor_account_requires_attention(member)
        end

        it "is false if the account has an address" do
          va.update(contact: Suma::Fixtures.anon_proxy_member_contact(member:).email.create)
          Suma::Mobility::VendorAdapter::Fake.find_anon_proxy_vendor_account_results << va
          expect(ad).to be_anon_proxy_vendor_account_requires_attention(member)
        end
      end

      describe "when the vendor config uses registration (linked account)" do
        let(:va) { Suma::Fixtures.anon_proxy_vendor_account(member:).create }

        it "is true if the account is not registered" do
          Suma::Mobility::VendorAdapter::Fake.find_anon_proxy_vendor_account_results << va
          expect(ad).to be_anon_proxy_vendor_account_requires_attention(member)
        end

        it "is false if the account is registered" do
          va.update(registered_with_vendor: "no-id")
          Suma::Mobility::VendorAdapter::Fake.find_anon_proxy_vendor_account_results << va
          expect(ad).to_not be_anon_proxy_vendor_account_requires_attention(member)
        end
      end
    end
  end
end
