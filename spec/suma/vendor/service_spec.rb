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
    vs = Suma::Fixtures.vendor_service.mobility.create
    expect(vs.mobility_adapter).to be_a(Suma::Mobility::VendorAdapter::Fake)
  end

  describe "guard_usage!" do
    it "raises if there is a usage prohibited reason" do
      svc = Suma::Fixtures.vendor_service.create
      member = Suma::Fixtures.member.create
      expect { svc.guard_usage!(member, now: Time.now) }.to raise_error(Suma::Member::ReadOnlyMode)
    end
  end

  describe "usage_prohibited_reason" do
    let(:svc) { Suma::Fixtures.vendor_service.create }
    let(:now) { Time.now }

    it "uses the user read only reason" do
      member = Suma::Fixtures.member.create
      expect(svc.usage_prohibited_reason(member, now:)).to eq("read_only_unverified")
    end

    it "uses the cash balance reason if met", reset_configuration: Suma::Payment do
      member = Suma::Fixtures.member.onboarding_verified.create
      Suma::Payment.ensure_cash_ledger(member)
      expect(svc.usage_prohibited_reason(member, now:)).to be_nil
      Suma::Payment.minimum_cash_balance_for_services_cents = 100_00
      expect(svc.usage_prohibited_reason(member, now:)).to eq("usage_prohibited_cash_balance")
    end
  end
end
