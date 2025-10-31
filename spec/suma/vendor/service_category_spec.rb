# frozen_string_literal: true

RSpec.describe "Suma::Vendor::ServiceCategory", :db do
  let(:described_class) { Suma::Vendor::ServiceCategory }

  it "can fixture itself" do
    p = Suma::Fixtures.vendor_service_category.create
    expect(p).to be_a(described_class)
  end

  it "can add and remove services and products" do
    cat = Suma::Fixtures.vendor_service_category.food.create
    vs = Suma::Fixtures.vendor_service.create
    pro = Suma::Fixtures.product.create
    vs.add_category(cat)
    pro.add_vendor_service_category(cat)
    expect(vs.categories).to have_same_ids_as(cat)
    expect(pro.vendor_service_categories).to have_same_ids_as(cat)
  end

  it "knows its ancestry and can tsort" do
    a1 = Suma::Fixtures.vendor_service_category.create(name: "a1")
    b1_a1 = Suma::Fixtures.vendor_service_category.create(parent: a1, name: "b1_a1")
    b2_a1 = Suma::Fixtures.vendor_service_category.create(parent: a1, name: "b2_a1")
    c1_b1 = Suma::Fixtures.vendor_service_category.create(parent: b1_a1, name: "c1_b1")
    c2_b1 = Suma::Fixtures.vendor_service_category.create(parent: b1_a1, name: "c2_b1")
    c1_b2 = Suma::Fixtures.vendor_service_category.create(parent: b2_a1, name: "c1_b2")
    d1_c2 = Suma::Fixtures.vendor_service_category.create(parent: c2_b1, name: "d1_c2")
    expect(a1.children).to have_same_ids_as(b1_a1, b2_a1)
    expect(a1.tsort).to have_same_ids_as(c1_b2, b2_a1, d1_c2, c2_b1, c1_b1, b1_a1, a1).ordered
    expect(b2_a1.tsort).to have_same_ids_as(c1_b2, b2_a1).ordered
    expect(d1_c2.tsort).to have_same_ids_as(d1_c2).ordered

    expect(a1).to be_ancestor_of(a1)
    expect(a1).to be_ancestor_of(d1_c2)
    expect(d1_c2).to be_ancestor_of(d1_c2)
    expect(d1_c2).to_not be_ancestor_of(b2_a1)

    expect(a1).to be_descendant_of(a1)
    expect(d1_c2).to_not be_descendant_of(c1_b1)
    expect(d1_c2).to be_descendant_of(c2_b1)
    expect(d1_c2).to be_descendant_of(d1_c2)
  end

  it "can tsort all" do
    a1 = Suma::Fixtures.vendor_service_category.create(name: "a1")
    b1_a1 = Suma::Fixtures.vendor_service_category.create(parent: a1, name: "b1")
    b2_a1 = Suma::Fixtures.vendor_service_category.create(parent: a1, name: "b2")
    c1_b1 = Suma::Fixtures.vendor_service_category.create(parent: b1_a1, name: "c3")
    z1 = Suma::Fixtures.vendor_service_category.create(name: "z1")
    y1_x1 = Suma::Fixtures.vendor_service_category.create(parent: z1, name: "y1")

    expect(described_class.tsort_all).to have_same_ids_as(a1, b1_a1, c1_b1, b2_a1, z1, y1_x1).ordered
  end

  describe "hierarchy_depth" do
    it "is correct" do
      a1 = Suma::Fixtures.vendor_service_category.create(name: "a")
      b1_a1 = Suma::Fixtures.vendor_service_category.create(name: "b", parent: a1)
      c1_b1 = Suma::Fixtures.vendor_service_category.create(name: "c", parent: b1_a1)

      expect(a1).to have_attributes(hierarchy_depth: 0)
      expect(a1).to have_attributes(hierarchy_up: [a1])
      expect(b1_a1).to have_attributes(hierarchy_depth: 1)
      expect(b1_a1).to have_attributes(hierarchy_up: [b1_a1, a1])
      expect(c1_b1).to have_attributes(hierarchy_depth: 2)
      expect(c1_b1).to have_attributes(hierarchy_up: [c1_b1, b1_a1, a1])
    end
  end

  describe "labels" do
    it "renders hierarchical" do
      a = Suma::Fixtures.vendor_service_category(name: "A").create
      b = Suma::Fixtures.vendor_service_category.create(name: "B", parent: a)
      c = Suma::Fixtures.vendor_service_category.create(name: "C", parent: b)
      d = Suma::Fixtures.vendor_service_category.create(name: "D", parent: c)
      expect(a).to have_attributes(full_label: "A", hierarchical_label: "A")
      expect(b).to have_attributes(full_label: "A - B", hierarchical_label: "└ B")
      expect(c).to have_attributes(full_label: "A - B - C", hierarchical_label: "└─ C")
      expect(d).to have_attributes(hierarchical_label: "└── D")
    end
  end
end
