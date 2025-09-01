# frozen_string_literal: true

RSpec.describe "Suma::Program::Pricing", :db do
  let(:described_class) { Suma::Program::Pricing }

  it "has associations and reserve associations" do
    pvs = Suma::Fixtures.program_pricing.create
    expect(pvs).to have_attributes(
      program: be_a(Suma::Program),
      vendor_service: be_a(Suma::Vendor::Service),
      vendor_service_rate: be_a(Suma::Vendor::ServiceRate),
    )
    expect(pvs.program.pricings).to contain_exactly(be === pvs)
    expect(pvs.vendor_service.program_pricings).to contain_exactly(be === pvs)
    expect(pvs.vendor_service_rate.program_pricings).to contain_exactly(be === pvs)
  end

  describe "datasets" do
    it "can limit to programs to those eligible to a member" do
      pp1 = Suma::Fixtures.program_pricing.create
      pp2 = Suma::Fixtures.program_pricing.create
      m = Suma::Fixtures.member.create
      Suma::Fixtures.program_enrollment.create(member: m, program: pp2.program)
      expect(described_class.eligible_to(m, as_of: Time.now).all).to have_same_ids_as(pp2)
    end

    it "can compress program pricing so that the pricing with the lowest rate ordinal is chosen" do
      vs = Suma::Fixtures.vendor_service.create
      rate2 = Suma::Fixtures.vendor_service_rate.create(ordinal: 2)
      rate1 = Suma::Fixtures.vendor_service_rate.create(ordinal: 1)
      rate3 = Suma::Fixtures.vendor_service_rate.create(ordinal: 3)
      pp2 = Suma::Fixtures.program_pricing.create(vendor_service: vs, vendor_service_rate: rate2)
      pp1 = Suma::Fixtures.program_pricing.create(vendor_service: vs, vendor_service_rate: rate1)
      pp3 = Suma::Fixtures.program_pricing.create(vendor_service: vs, vendor_service_rate: rate3)

      expect(described_class.compress.all).to have_same_ids_as(pp1)
    end
  end
end
