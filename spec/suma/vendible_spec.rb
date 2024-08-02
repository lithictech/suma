# frozen_string_literal: true

RSpec.describe Suma::Vendible, db: true do
  it "can fixture offerings with vendible groups" do
    g = Suma::Fixtures.vendible_group.with_offering.create
    expect(g.commerce_offerings).to have_length(1)
    o = g.commerce_offerings.first
    expect(o.vendible_groups).to contain_exactly(be === g)
  end

  it "can fixture vendor services with vendible groups" do
    g = Suma::Fixtures.vendible_group.with_vendor_service.create
    expect(g.vendor_services).to have_length(1)
    o = g.vendor_services.first
    expect(o.vendible_groups).to contain_exactly(be === g)
  end

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

  describe "groupings" do
    it "groups offerings and services into hierarchical vendibles" do
      o1d = Suma::Fixtures.offering.description("ddd").create
      o1a_early = Suma::Fixtures.offering.description("aaa").create(period_end: 2.days.from_now)
      o1a_late = Suma::Fixtures.offering.description("aaa").create(period_end: 5.days.from_now)
      o2 = Suma::Fixtures.offering.description("o2").create
      vs1b = Suma::Fixtures.vendor_service.create(external_name: "bbb")
      vs1c = Suma::Fixtures.vendor_service.create(external_name: "ccc")
      vs_no_group = Suma::Fixtures.vendor_service.create

      vg2 = Suma::Fixtures.vendible_group.with(o2).named("vg2").create(ordinal: 2)
      vg1 = Suma::Fixtures.vendible_group.with(o1a_late, o1a_early, o1d, vs1c, vs1b).named("vg1").create(ordinal: 1)
      vg3 = Suma::Fixtures.vendible_group.named("vg3").create(ordinal: 3)
      vg4 = Suma::Fixtures.vendible_group.with(o1a_early).named("vg4").create(ordinal: 4)

      grp = described_class.groupings([o1d, o1a_early, o1a_late, o2, vs1b, vs1c, vs_no_group])
      expect(grp).to match(
        [
          have_attributes(
            group: be === vg1,
            vendibles: [
              have_attributes(name: have_attributes(en: "aaa")),
              have_attributes(name: have_attributes(en: "aaa")),
              have_attributes(name: have_attributes(en: "bbb")),
              have_attributes(name: have_attributes(en: "ccc")),
              have_attributes(name: have_attributes(en: "ddd")),
            ],
          ),
          have_attributes(group: be === vg2, vendibles: [have_attributes(name: have_attributes(en: "o2"))]),
          have_attributes(group: be === vg4, vendibles: [have_attributes(name: have_attributes(en: "aaa"))]),
        ],
      )
    end
  end
end
