# frozen_string_literal: true

RSpec.describe "Suma::Program::Component", :db do
  let(:described_class) { Suma::Program::Component }

  it "can be created from an offering" do
    o = Suma::Fixtures.offering.create
    v = described_class.from_commerce_offering(o)
    expect(v).to have_attributes(
      name: be === o.description,
      until: o.period.end,
      image: be_a(Suma::Image),
      link: "/food/#{o.id}",
    )
  end

  it "can be created from a vendor service" do
    o = Suma::Fixtures.vendor_service.create
    v = described_class.from_vendor_service(o)
    expect(v).to have_attributes(
      name: have_attributes(en: o.external_name, es: o.external_name),
      until: o.period.end,
      image: be_a(Suma::Image),
      link: "/mobility",
    )
  end

  describe "from" do
    it "handles supported types" do
      expect(described_class.from(Suma::Fixtures.offering.create)).to be_a(described_class)
      expect(described_class.from(Suma::Fixtures.vendor_service.create)).to be_a(described_class)
    end

    it "errors for unsupported types" do
      expect do
        described_class.from(Suma::Fixtures.member.create)
      end.to raise_error(TypeError, /source type 'Suma::Member': #<Suma::Member/)
    end
  end
end
