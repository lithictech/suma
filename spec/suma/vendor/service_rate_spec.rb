# frozen_string_literal: true

RSpec.describe "Suma::Vendor::ServiceRate", :db do
  let(:described_class) { Suma::Vendor::ServiceRate }

  it "can fixture itself" do
    p = Suma::Fixtures.vendor_service_rate.create
    expect(p).to be_a(described_class)
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

  describe "localization" do
    it "can describe its cost template and vars" do
      r = Suma::Fixtures.vendor_service_rate.surcharge(10).unit_amount(100).create
      expect(r.localization_vars(payment_trigger: nil)).to eq(
        chargeable_percentage: nil,
        chargeable_surcharge_cents: nil,
        chargeable_unit_cents: nil,
        surcharge_cents: 10,
        surcharge_currency: "USD",
        undiscounted_surcharge_cents: nil,
        undiscounted_unit_cents: nil,
        unit_cents: 100,
        unit_currency: "USD",
      )

      r.undiscounted_rate = Suma::Fixtures.vendor_service_rate.surcharge(100).unit_amount(1000).create
      expect(r.localization_vars(payment_trigger: nil)).to eq(
        chargeable_percentage: nil,
        chargeable_surcharge_cents: nil,
        chargeable_unit_cents: nil,
        surcharge_cents: 10,
        surcharge_currency: "USD",
        undiscounted_surcharge_cents: 100,
        undiscounted_unit_cents: 1000,
        unit_cents: 100,
        unit_currency: "USD",
      )

      payment_trigger = Suma::Fixtures.payment_trigger.matching(1).create
      expect(r.localization_vars(payment_trigger:)).to eq(
        chargeable_percentage: 50,
        chargeable_surcharge_cents: 5,
        chargeable_unit_cents: 50,
        surcharge_cents: 10,
        surcharge_currency: "USD",
        undiscounted_surcharge_cents: 100,
        undiscounted_unit_cents: 1000,
        unit_cents: 100,
        unit_currency: "USD",
      )
    end
  end
end
