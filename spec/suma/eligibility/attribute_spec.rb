# frozen_string_literal: true

RSpec.describe "Suma::Eligibility::Attribute", :db do
  let(:described_class) { Suma::Eligibility::Attribute }

  it "can be fixtured" do
    a = Suma::Fixtures.eligibility_attribute.create
    expect(a).to be_a(described_class)
  end

  it "can accumulate all parents" do
    g1 = Suma::Fixtures.eligibility_attribute.create(name: "g1")
    p1 = Suma::Fixtures.eligibility_attribute.parent(g1).create(name: "p1")
    c1 = Suma::Fixtures.eligibility_attribute.parent(p1).create(name: "c1")
    c2 = Suma::Fixtures.eligibility_attribute.parent(p1).create(name: "c2")
    p_a1 = Suma::Fixtures.eligibility_attribute.parent(g1).create(name: "p_a1")
    c_a1 = Suma::Fixtures.eligibility_attribute.parent(p_a1).create(name: "c_a1")
    p_b1 = Suma::Fixtures.eligibility_attribute.create(name: "p_b1")
    c_b1 = Suma::Fixtures.eligibility_attribute.parent(p_b1).create(name: "c_b1")

    # expect(described_class.accumulate([c1])).to have_same_ids_as(c1, p1, g1)
    # expect(described_class.accumulate([c1, c2])).to have_same_ids_as(c1, c2, p1, g1)
    expect(described_class.accumulate([c1, c_a1, c_b1])).to have_same_ids_as(c1, c_a1, c_b1, p1, g1, p_a1, p_b1)
  end
end
