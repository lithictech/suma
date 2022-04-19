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
    expect(vs.mobility_adapter).to be_a(Suma::Mobility::FakeVendorAdapter)
  end

  describe "one_rate" do
    let(:vs) { Suma::Fixtures.vendor_service.create }

    it "returns the first rate" do
      r = Suma::Fixtures.vendor_service_rate.for_service(vs).create
      expect(vs.one_rate).to be === r
    end

    it "errors if there are no rates" do
      expect { vs.one_rate }.to raise_error(/no rates/)
    end

    it "errors if there is more than one rate defined" do
      Suma::Fixtures.vendor_service_rate.for_service(vs).create
      Suma::Fixtures.vendor_service_rate.for_service(vs).create
      expect { vs.one_rate }.to raise_error(/too many rates/)
    end
  end
end
