# frozen_string_literal: true

RSpec.describe "Suma::Vendor::ServiceCategory", :db do
  let(:described_class) { Suma::Vendor::ServiceCategory }

  it "can fixture itself" do
    p = Suma::Fixtures.vendor_service_category.create
    expect(p).to be_a(described_class)
  end

  it "can add and remove services" do
    cat = Suma::Fixtures.vendor_service_category.food.create
    vs = Suma::Fixtures.vendor_service.create
    cat.add_service(vs)
    expect(cat.services).to have_same_ids_as(vs)
  end

  it "knows its ancestry and can tsort" do
    a1 = Suma::Fixtures.vendor_service_category.create
    b1_a1 = Suma::Fixtures.vendor_service_category.create(parent: a1)
    b2_a1 = Suma::Fixtures.vendor_service_category.create(parent: a1)
    c1_b1 = Suma::Fixtures.vendor_service_category.create(parent: b1_a1)
    c2_b1 = Suma::Fixtures.vendor_service_category.create(parent: b1_a1)
    c1_b2 = Suma::Fixtures.vendor_service_category.create(parent: b2_a1)
    d1_c2 = Suma::Fixtures.vendor_service_category.create(parent: c2_b1)
    expect(a1.children).to have_same_ids_as(b1_a1, b2_a1)
    expect(a1.tsort).to have_same_ids_as(c1_b1, d1_c2, c2_b1, b1_a1, c1_b2, b2_a1, a1).ordered
    expect(b2_a1.tsort).to have_same_ids_as(c1_b2, b2_a1).ordered
    expect(d1_c2.tsort).to have_same_ids_as(d1_c2).ordered
  end

  describe "hierarchy_depth" do
    it "is correct" do
      a1 = Suma::Fixtures.vendor_service_category.create
      b1_a1 = Suma::Fixtures.vendor_service_category.create(parent: a1)
      c1_b1 = Suma::Fixtures.vendor_service_category.create(parent: b1_a1)

      expect(a1).to have_attributes(hierarchy_depth: 0)
      expect(b1_a1).to have_attributes(hierarchy_depth: 1)
      expect(c1_b1).to have_attributes(hierarchy_depth: 2)
    end
  end

  describe "full_label" do
    it "renders hierarchical" do
      a = Suma::Fixtures.vendor_service_category(name: "A").create
      b = Suma::Fixtures.vendor_service_category.create(name: "B", parent: a)
      c = Suma::Fixtures.vendor_service_category.create(name: "C", parent: b)
      expect(a).to have_attributes(full_label: "A")
      expect(b).to have_attributes(full_label: "A - B")
      expect(c).to have_attributes(full_label: "A - B - C")
    end
  end
end
