# frozen_string_literal: true

RSpec.describe "Suma::Program::Enrollment", :db do
  let(:described_class) { Suma::Program::Enrollment }

  describe "datasets" do
    describe "active" do
      it "includes rows were now is within the period, and a member has been approved and not unenrolled" do
        expired = Suma::Fixtures.program.expired.create
        future = Suma::Fixtures.program.future.create
        active = Suma::Fixtures.program.create
        member = Suma::Fixtures.member.create
        Suma::Fixtures.program_enrollment(program: active, member:).unapproved.create
        Suma::Fixtures.program_enrollment(program: active, member:).unenrolled.create
        enrolled = Suma::Fixtures.program_enrollment(program: active, member:).create
        Suma::Fixtures.program_enrollment(program: expired, member:).create
        Suma::Fixtures.program_enrollment(program: future, member:).create
        expect(described_class.active.all).to have_same_ids_as(enrolled)
      end
    end
  end
end
