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
    it "can find rows available to a member based on program enrollment" do
      mem_no_programs = Suma::Fixtures.member.create
      mem_enrolled = Suma::Fixtures.member.create
      mem_unenrolled = Suma::Fixtures.member.create

      program = Suma::Fixtures.program.create
      Suma::Fixtures.program_enrollment.create(program:, member: mem_enrolled)
      Suma::Fixtures.program_enrollment.unenrolled.create(program:, member: mem_unenrolled)

      no_programs = Suma::Fixtures.vendor_service.create
      with_program = Suma::Fixtures.vendor_service.with_programs(program).create

      as_of = Time.now
      expect(described_class.eligible_to(mem_no_programs, as_of:).all).to have_same_ids_as(no_programs)
      expect(described_class.eligible_to(mem_enrolled, as_of:).all).to have_same_ids_as(no_programs, with_program)
      expect(described_class.eligible_to(mem_unenrolled, as_of:).all).to have_same_ids_as(no_programs)
    end
  end

  describe "associations" do
    it "knows its program enrollments" do
      e1 = Suma::Fixtures.program_enrollment.create
      e2 = Suma::Fixtures.program_enrollment.create
      e3 = Suma::Fixtures.program_enrollment.create

      o = Suma::Fixtures.vendor_service.create
      o.add_program(e1.program)
      o.add_program(e2.program)
      expect(o.program_enrollments).to have_same_ids_as(e1, e2)
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
