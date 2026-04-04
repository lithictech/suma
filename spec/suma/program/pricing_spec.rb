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
end
