# frozen_string_literal: true

RSpec.describe "Suma::Program", :db do
  let(:described_class) { Suma::Program }

  it "can fixture with offerings" do
    g = Suma::Fixtures.program.with_offering.create
    expect(g.commerce_offerings).to have_length(1)
    o = g.commerce_offerings.first
    expect(o.programs).to contain_exactly(be === g)
  end

  it "can fixture with vendor services" do
    g = Suma::Fixtures.program.with_vendor_service.create
    expect(g.vendor_services).to have_length(1)
    o = g.vendor_services.first
    expect(o.programs).to contain_exactly(be === g)
  end

  describe "datasets" do
    describe "active" do
      it "includes rows were now is within the period" do
        Suma::Fixtures.program.expired.create
        Suma::Fixtures.program.future.create
        active = Suma::Fixtures.program.create
        expect(described_class.active(as_of: Time.now).all).to have_same_ids_as(active)
      end
    end
  end

  it "can associate with an image" do
    p = Suma::Fixtures.program.with_image.create
    expect(p.images).to have_length(1)
  end

  describe "#period_end_visible" do
    it "returns nil if the offering ends far in the future" do
      t = 1.year.from_now
      o = Suma::Fixtures.program.create(period: 1.year.ago..t)
      expect(o.period_end_visible).to match_time(t)
      o.period_end = 10.years.from_now
      expect(o.period_end_visible).to be_nil
    end
  end
end
