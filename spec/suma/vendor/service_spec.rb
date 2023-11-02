# frozen_string_literal: true

RSpec.describe "Suma::Vendor::Service", :db do
  let(:described_class) { Suma::Vendor::Service }

  it "can fixture itself" do
    p = Suma::Fixtures.vendor_service.create
    expect(p).to be_a(described_class)
  end

  it "can add and remove categories" do
    vs = Suma::Fixtures.vendor_service.food.create
    expect(vs.categories).to contain_exactly(have_attributes(slug: "food"))
    Suma::Fixtures.vendor_service.food.create
  end

  it "can create mobility vendor adapters" do
    vs = Suma::Fixtures.vendor_service.mobility.create
    expect(vs.mobility_adapter).to be_a(Suma::Mobility::VendorAdapter::Fake)
  end

  describe "datasets" do
    it "can find rows available to a member based on constraints" do
      mem_no_constraints = Suma::Fixtures.member.create
      mem_verified_constraint = Suma::Fixtures.member.create
      mem_rejected_constraint = Suma::Fixtures.member.create

      constraint = Suma::Fixtures.eligibility_constraint.create
      mem_verified_constraint.add_verified_eligibility_constraint(constraint)
      mem_rejected_constraint.add_rejected_eligibility_constraint(constraint)

      no_constraint = Suma::Fixtures.vendor_service.create
      with_constraint = Suma::Fixtures.vendor_service.with_constraints(constraint).create

      expect(described_class.eligible_to(mem_no_constraints).all).to have_same_ids_as(no_constraint)
      expect(described_class.eligible_to(mem_verified_constraint).all).to have_same_ids_as(
        no_constraint,
        with_constraint,
      )
      expect(described_class.eligible_to(mem_rejected_constraint).all).to have_same_ids_as(no_constraint)
    end
  end

  describe "one_rate" do
    let(:vs) { Suma::Fixtures.vendor_service.create }

    it "returns the first rate" do
      r = Suma::Fixtures.vendor_service_rate.for_service(vs).create
      expect(vs.one_rate).to be === r
    end

    it "errors if there are no rates" do
      expect { vs.one_rate }.to raise_error(/no rates/)
    end

    it "errors if there is more than one rate defined" do
      Suma::Fixtures.vendor_service_rate.for_service(vs).create
      Suma::Fixtures.vendor_service_rate.for_service(vs).create
      expect { vs.one_rate }.to raise_error(/too many rates/)
    end
  end
end
