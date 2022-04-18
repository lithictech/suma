# frozen_string_literal: true

RSpec.describe "Suma::Vendor::ServiceRate", :db do
  let(:described_class) { Suma::Vendor::ServiceRate }

  it "can fixture itself" do
    p = Suma::Fixtures.vendor_service_rate.create
    expect(p).to be_a(described_class)
  end

  it "has associations to vendor service" do
    svc1 = Suma::Fixtures.vendor_service.create
    svc2 = Suma::Fixtures.vendor_service.create
    r = Suma::Fixtures.vendor_service_rate.for_service(svc1).create
    expect(svc1.rates).to contain_exactly(be === r)

    expect(svc2.rates).to be_empty
    svc2.add_rate(r)
    expect(svc2.rates).to contain_exactly(be === r)

    expect(r.refresh.services).to include(be === svc1, be === svc2)
  end

  describe "calculate_total" do
    it "multiplies units by unit cost" do
      r = Suma::Fixtures.vendor_service_rate(unit_amount: Money.new(500)).create
      expect(r.calculate_total(5)).to cost("$25")
    end
    it "applies a surcharge" do
      r = Suma::Fixtures.vendor_service_rate(unit_amount: Money.new(500), surcharge: Money.new(50)).create
      expect(r.calculate_total(5)).to cost("$25.50")
    end
    it "applies a unit offset" do
      r = Suma::Fixtures.vendor_service_rate(unit_amount: Money.new(500), unit_offset: 3).create
      expect(r.calculate_total(5)).to cost("$10")
    end
    it "cannot use a negative unit offset" do
      r = Suma::Fixtures.vendor_service_rate(unit_amount: Money.new(500), unit_offset: 30).create
      expect(r.calculate_total(5)).to cost("$0")
    end
  end
  describe "calculate_undiscounted_total" do
    it "calculates the total of the linked undiscounted total" do
      r = Suma::Fixtures.vendor_service_rate(surcharge: Money.new(250)).
        discounted_by(0.75).
        create
      expect(r.calculate_undiscounted_total(5)).to cost("$10")
    end
    it "returns calculate_total if there is no undiscounted total" do
      r = Suma::Fixtures.vendor_service_rate(surcharge: Money.new(50)).create
      expect(r.calculate_undiscounted_total(5)).to cost("$0.50")
    end
  end
  describe "discount" do
    it "returns the discount" do
      r = Suma::Fixtures.vendor_service_rate(surcharge: Money.new(250)).
        discounted_by(0.75).
        create
      expect(r.discount(5)).to cost("$7.50")
    end
    it "can calculate a 0% discount" do
      r = Suma::Fixtures.vendor_service_rate(surcharge: Money.new(50)).create
      expect(r.discount(5)).to cost("$0")
    end
  end
  describe "discount_percentage" do
    it "returns the integer discount percentage" do
      r = Suma::Fixtures.vendor_service_rate(surcharge: Money.new(250)).
        discounted_by(0.75).
        create
      expect(r.discount_percentage(5)).to eq(75)
    end
    it "can calculate a 0% discount" do
      r = Suma::Fixtures.vendor_service_rate(surcharge: Money.new(50)).create
      expect(r.discount_percentage(5)).to be_zero
    end
  end
end
