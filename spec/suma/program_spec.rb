# frozen_string_literal: true

RSpec.describe "Suma::Program", :db do
  let(:described_class) { Suma::Program }

  it "can fixture with offerings" do
    g = Suma::Fixtures.program.with_offering.create
    expect(g.commerce_offerings).to have_length(1)
    o = g.commerce_offerings.first
    expect(o.programs).to contain_exactly(be === g)
  end

  it "can fixture with pricing" do
    g = Suma::Fixtures.program.with_pricing.create
    expect(g.pricings).to have_length(1)
    o = g.pricings.first
    expect(o.program).to be === g
    unsaved_pricing = Suma::Fixtures.program_pricing(
      vendor_service: Suma::Fixtures.vendor_service.create,
      vendor_service_rate: Suma::Fixtures.vendor_service_rate.create,
    ).instance
    g2 = Suma::Fixtures.program.with_pricing(unsaved_pricing).create
    expect(g2.pricings).to contain_exactly(be === unsaved_pricing)
  end

  describe "eligibility" do
    it "includes a dataset of only active rows" do
      Suma::Fixtures.program.expired.create
      Suma::Fixtures.program.future.create
      active = Suma::Fixtures.program.create
      expect(described_class.dataset.active_at(Time.now).all).to have_same_ids_as(active)
    end

    it "has a dataset with potential rows for a member" do
      prog = Suma::Fixtures.program.create
      no_assignment = Suma::Fixtures.program.create
      m = Suma::Fixtures.member.create
      assignment = Suma::Fixtures.eligibility_assignment(member: m).create
      Suma::Fixtures.eligibility_requirement.attribute(assignment.attribute).create(resource: prog)
      expect(described_class.dataset.potentially_eligible_to(m).all).to have_same_ids_as(
        prog,
        # NOTE: This test will/should fail when we start excluding rows that cannot possibly match.
        # That is a good thing; remove the following line.
        no_assignment,
      )
    end

    it "can reify and limit a dataset to only actually eligible rows" do
      a1 = Suma::Fixtures.eligibility_attribute.create
      a2 = Suma::Fixtures.eligibility_attribute.create

      prog_and = Suma::Fixtures.program.create
      prog_or = Suma::Fixtures.program.create
      # prog_and has AND (so won't be eligible to member with just 1 attr), prog_or has OR (so will be eligible)
      Suma::Fixtures.eligibility_requirement.create(
        resource: prog_and,
        expression: Suma::Fixtures.eligibility_expression.branch([a1, a2]).and.create,
      )
      Suma::Fixtures.eligibility_requirement.create(
        resource: prog_or,
        expression: Suma::Fixtures.eligibility_expression.branch([a1, a2]).or.create,
      )
      # Assign the first attribute only, so the 'OR' program is matched.
      m = Suma::Fixtures.member.create
      Suma::Fixtures.eligibility_assignment(member: m, attribute: a1).create
      expect(described_class.dataset.evaluate_eligible_to(m)).to have_same_ids_as(prog_or)
    end

    it "has a helper dataset that combines time and eligibility checks" do
      a1 = Suma::Fixtures.eligibility_attribute.create
      a2 = Suma::Fixtures.eligibility_attribute.create

      expired = Suma::Fixtures.program.expired.create
      prog_and = Suma::Fixtures.program.create
      prog_or = Suma::Fixtures.program.create
      # prog_and has AND (so won't be eligible to member with just 1 attr), prog_or has OR (so will be eligible)
      expr_fac = Suma::Fixtures.eligibility_expression.branch([a1, a2])
      Suma::Fixtures.eligibility_requirement.create(
        resource: prog_and,
        expression: expr_fac.and.create,
      )
      Suma::Fixtures.eligibility_requirement.create(
        resource: prog_or,
        expression: expr_fac.or.create,
      )
      Suma::Fixtures.eligibility_requirement.create(
        resource: expired,
        expression: expr_fac.or.create,
      )
      # Assign the first attribute only, so the 'OR' program is matched.
      m = Suma::Fixtures.member.create
      Suma::Fixtures.eligibility_assignment(member: m, attribute: a1).create
      expect(described_class.dataset.fetch_eligible_to(m, as_of: Time.now)).to have_same_ids_as(prog_or)
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
