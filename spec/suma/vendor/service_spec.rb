# frozen_string_literal: true

RSpec.describe "Suma::Vendor::Service", :db do
  let(:described_class) { Suma::Vendor::Service }

  it "can fixture itself" do
    p = Suma::Fixtures.vendor_service.create
    expect(p).to be_a(described_class)
  end

  it "can add and remove categories" do
    vs = Suma::Fixtures.vendor_service.food.create
    expect(vs.categories).to contain_exactly(have_attributes(slug: "food"))
    Suma::Fixtures.vendor_service.food.create
  end

  it "can create mobility vendor adapters" do
    vs = Suma::Fixtures.vendor_service.mobility_maas.create
    expect(vs.mobility_adapter.trip_provider).to be_a(Suma::Mobility::TripProvider::Internal)
  end

  describe "mobility adapter settings" do
    it "can set and describe all options" do
      vs = Suma::Fixtures.vendor_service.create
      expect(vs.class.mobility_adapter_setting_options).to match_array(
        [
          have_attributes(name: "No Adapter/Non-Mobility", value: "no_adapter"),
          have_attributes(name: "Deep Linking (suma sends receipts)", value: "deep_linking_suma_receipts"),
          have_attributes(name: "Deep Linking (vendor sends receipts)", value: "deep_linking_vendor_receipts"),
          have_attributes(name: "MaaS: lime_maas", value: "lime_maas"),
          have_attributes(name: "MaaS: internal", value: "internal"),
        ],
      )

      expect(vs).to have_attributes(
        mobility_adapter_setting: "no_adapter",
        mobility_adapter_setting_name: "No Adapter/Non-Mobility",
        mobility_adapter: nil,
      )

      vs.mobility_adapter_setting = "deep_linking_suma_receipts"
      expect(vs).to have_attributes(
        mobility_adapter_setting: "deep_linking_suma_receipts",
        mobility_adapter_setting_name: "Deep Linking (suma sends receipts)",
        mobility_adapter: have_attributes(uses_deep_linking: true, trip_provider_key: "", send_receipts: true),
      )

      vs.mobility_adapter_setting = "deep_linking_vendor_receipts"
      expect(vs).to have_attributes(
        mobility_adapter_setting: "deep_linking_vendor_receipts",
        mobility_adapter: have_attributes(uses_deep_linking: true, trip_provider_key: "", send_receipts: false),
      )

      vs.mobility_adapter_setting = "internal"
      expect(vs).to have_attributes(
        mobility_adapter_setting: "internal",
        mobility_adapter: have_attributes(uses_deep_linking: false, trip_provider_key: "internal"),
      )

      vs.mobility_adapter_setting = "deep_linking_vendor_receipts"
      expect(vs).to have_attributes(
        mobility_adapter_setting: "deep_linking_vendor_receipts",
        mobility_adapter: have_attributes(uses_deep_linking: true, trip_provider_key: ""),
      )

      vs.mobility_adapter_setting = "no_adapter"
      expect(vs).to have_attributes(
        mobility_adapter_setting: "no_adapter",
        mobility_adapter: nil,
      )
    end

    it "errors for an invalid setting" do
      vs = Suma::Fixtures.vendor_service.create
      expect { vs.mobility_adapter_setting = "foo" }.to raise_error(Sequel::ValidationFailed)
    end
  end

  describe "guard_usage!" do
    let(:svc) { Suma::Fixtures.vendor_service.create }
    let(:rate) { Suma::Fixtures.vendor_service_rate.create }
    let(:now) { Time.now }

    it "raises if there is a usage prohibited reason" do
      member = Suma::Fixtures.member.create
      expect { svc.guard_usage!(member, rate:, now:) }.to raise_error(Suma::Member::ReadOnlyMode)
    end
  end

  describe "usage_prohibited_reason" do
    let(:svc) { Suma::Fixtures.vendor_service.create }
    let(:rate) { Suma::Fixtures.vendor_service_rate.create }
    let(:now) { Time.now }

    it "uses the user read only reason" do
      member = Suma::Fixtures.member.create
      expect(svc.usage_prohibited_reason(member, rate:, now:)).to eq("read_only_unverified")
    end

    it "uses the cash balance reason if met", reset_configuration: Suma::Payment do
      member = Suma::Fixtures.member.onboarding_verified.create
      Suma::Payment.ensure_cash_ledger(member)
      expect(svc.usage_prohibited_reason(member, rate:, now:)).to be_nil
      Suma::Payment.minimum_cash_balance_for_services_cents = 100_00
      expect(svc.usage_prohibited_reason(member, rate:, now:)).to eq("usage_prohibited_cash_balance")
    end

    it "uses the instrument required reason if the rate is nonzero and the member has no instrument" do
      member = Suma::Fixtures.member.onboarding_verified.create
      Suma::Payment.ensure_cash_ledger(member)
      expect(svc.usage_prohibited_reason(member, rate:, now:)).to be_nil
      rate.update(surcharge_cents: 100)
      expect(svc.usage_prohibited_reason(member, rate:, now:)).to eq("usage_prohibited_instrument_required")
      card = Suma::Fixtures.card.member(member).create
      expect(svc.usage_prohibited_reason(member, rate:, now:)).to be_nil
      card.soft_delete
      expect(svc.usage_prohibited_reason(member, rate:, now:)).to eq("usage_prohibited_instrument_required")
    end
  end
end
