# frozen_string_literal: true

RSpec.describe Suma::Program::Has, :db do
  describe "datasets" do
    it "can find instances eligible to a member based on programs" do
      as_of = Time.now
      mem_no_constraints = Suma::Fixtures.member.create
      member_in_program = Suma::Fixtures.member.create
      member_unapproved = Suma::Fixtures.member.create
      member_unenrolled = Suma::Fixtures.member.create

      program = Suma::Fixtures.program.create
      Suma::Fixtures.program_enrollment(member: member_in_program, program:).create
      Suma::Fixtures.program_enrollment(member: member_unapproved, program:).unapproved.create
      Suma::Fixtures.program_enrollment(member: member_unenrolled, program:).unenrolled.create

      no_program = Suma::Fixtures.offering.create
      with_program = Suma::Fixtures.offering.with_programs(program).create

      expect(Suma::Commerce::Offering.eligible_to(mem_no_constraints, as_of:).all).to have_same_ids_as(no_program)
      expect(Suma::Commerce::Offering.eligible_to(member_in_program, as_of:).all).to have_same_ids_as(
        no_program,
        with_program,
      )
      expect(Suma::Commerce::Offering.eligible_to(member_unapproved, as_of:).all).to have_same_ids_as(no_program)
      expect(Suma::Commerce::Offering.eligible_to(member_unenrolled, as_of:).all).to have_same_ids_as(no_program)

      # Test the instance methods
      expect(no_program).to be_eligible_to(mem_no_constraints, as_of:)
      expect(no_program).to be_eligible_to(member_in_program, as_of:)
      expect(no_program).to be_eligible_to(member_unapproved, as_of:)

      expect(with_program).to_not be_eligible_to(mem_no_constraints, as_of:)
      expect(with_program).to be_eligible_to(member_in_program, as_of:)
      expect(with_program).to_not be_eligible_to(member_unapproved, as_of:)
    end

    it "does not include unconstrained instances if UNPROGRAMMED_ACCESSIBLE is false" do
      as_of = Time.now
      mem_no_constraints = Suma::Fixtures.member.create
      member_in_program = Suma::Fixtures.member.create

      program = Suma::Fixtures.program.create
      Suma::Fixtures.program_enrollment(member: member_in_program, program:).create

      no_program = Suma::Fixtures.offering.create
      with_program = Suma::Fixtures.offering.with_programs(program).create

      expect(Suma::Commerce::Offering.eligible_to(mem_no_constraints, as_of:).all).to have_same_ids_as(
        no_program,
      )
      expect(Suma::Commerce::Offering.eligible_to(member_in_program, as_of:).all).to have_same_ids_as(
        no_program,
        with_program,
      )
      expect(no_program).to be_eligible_to(mem_no_constraints, as_of:)
      expect(no_program).to be_eligible_to(member_in_program, as_of:)
      expect(with_program).to_not be_eligible_to(mem_no_constraints, as_of:)
      expect(with_program).to be_eligible_to(member_in_program, as_of:)

      stub_const("Suma::Program::UNPROGRAMMED_ACCESSIBLE", false)
      expect(Suma::Commerce::Offering.eligible_to(mem_no_constraints, as_of:).all).to be_empty
      expect(Suma::Commerce::Offering.eligible_to(member_in_program, as_of:).all).to have_same_ids_as(
        with_program,
      )
      expect(no_program).to_not be_eligible_to(mem_no_constraints, as_of:)
      expect(no_program).to_not be_eligible_to(member_in_program, as_of:)
      expect(with_program).to_not be_eligible_to(mem_no_constraints, as_of:)
      expect(with_program).to be_eligible_to(member_in_program, as_of:)
    end
  end
end
