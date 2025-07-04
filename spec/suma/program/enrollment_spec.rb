# frozen_string_literal: true

require "suma/behaviors"

RSpec.describe "Suma::Program::Enrollment", :db do
  let(:described_class) { Suma::Program::Enrollment }

  describe "datasets" do
    describe "active" do
      it "includes rows were now is within the period, and a member has been approved and not unenrolled" do
        expired = Suma::Fixtures.program.expired.create
        future = Suma::Fixtures.program.future.create
        active = Suma::Fixtures.program.create
        fac = Suma::Fixtures.program_enrollment
        unapproved = fac.unapproved.create(program: active)
        approved_in_future = fac.create(program: active, approved_at: 2.days.from_now)
        unenrolled = fac.unenrolled.create(program: active)
        unenrolled_in_future = fac.unenrolled(2.days.from_now).create(program: active)
        unenrolled_in_past = fac.unenrolled(2.days.ago).create(program: active)
        enrolled = fac.create(program: active)
        fac.create(program: expired)
        fac.create(program: future)
        expect(described_class.active(as_of: Time.now).all).to have_same_ids_as(enrolled, unenrolled_in_future)
      end
    end
  end

  it "can enroll members, organizations and roles" do
    org1 = Suma::Fixtures.organization.create
    org1_mem1 = Suma::Fixtures.organization_membership.verified(org1).create
    org1_mem2 = Suma::Fixtures.organization_membership.verified(org1).create

    org2 = Suma::Fixtures.organization.create
    org2_mem1 = Suma::Fixtures.organization_membership.verified(org2).create

    role = Suma::Role.create(name: "test")
    member_with_role = Suma::Fixtures.member.with_role(role).create

    program = Suma::Fixtures.program.create
    member_enrollment = Suma::Fixtures.program_enrollment(program:, member: org1_mem1.member).create
    org_enrollment = Suma::Fixtures.program_enrollment(program:, organization: org2).create
    role_enrollment = Suma::Fixtures.program_enrollment(program:, role:).create
    as_of = Time.now
    # This member should find the direct enrollment
    expect(program.enrollment_for(org1_mem1.member, as_of:)).to be === member_enrollment
    # But the org, and the other member, should not find an enrollment
    expect(program.enrollment_for(org1_mem1.verified_organization, as_of:)).to be_nil
    expect(program.enrollment_for(org1_mem2.member, as_of:)).to be_nil

    # The organization and its members should all find the enrollment
    expect(program.enrollment_for(org2_mem1.member, as_of:)).to be === org_enrollment
    expect(program.enrollment_for(org2, as_of:)).to be === org_enrollment

    expect(program.enrollment_for(member_with_role, as_of:)).to be === role_enrollment
    expect(program.enrollment_for(role, as_of:)).to be === role_enrollment
  end

  describe "enrollment_for" do
    let(:as_of) { Time.now }

    it "includes only unverified organization memberships" do
      om = Suma::Fixtures.organization_membership.verified.create
      pe = Suma::Fixtures.program_enrollment(organization: om.verified_organization).create
      expect(pe.program.enrollment_for(om.member, as_of:)).to be === pe
      om.update(verified_organization_id: nil, unverified_organization_name: om.verified_organization.name)
      expect(pe.program.enrollment_for(om.member, as_of:)).to be_nil
      expect(pe.program.enrollment_for(om.member, as_of:, include: :all)).to be_nil
    end

    it "filters inactive enrollments" do
      m = Suma::Fixtures.member.create
      pe = Suma::Fixtures.program_enrollment(member: m).unapproved.create
      expect(pe.program.enrollment_for(m, as_of:)).to be_nil
      expect(pe.program.enrollment_for(m, as_of:, include: :all)).to be === pe
      pe.update(approved_at: 5.days.ago)
      expect(pe.program.enrollment_for(m, as_of:)).to be === pe
      expect(pe.program.enrollment_for(m, as_of:, include: :all)).to be === pe
      pe.update(unenrolled_at: 2.days.ago)
      expect(pe.program.enrollment_for(m, as_of:)).to be_nil
      expect(pe.program.enrollment_for(m, as_of:, include: :all)).to be === pe
    end
  end

  it "can describe its enrollees" do
    pe = Suma::Fixtures.program_enrollment.instance
    member = Suma::Fixtures.member.create
    organization = Suma::Fixtures.organization.create
    role = Suma::Role.create(name: "test role")
    pe.set(member:)
    expect(pe).to have_attributes(enrollee_type: "Member", enrollee: be === member)
    pe.set(member: nil, organization:)
    expect(pe).to have_attributes(enrollee_type: "Organization", enrollee: be === organization)
    pe.set(organization: nil, role:)
    expect(pe).to have_attributes(enrollee_type: "Role", enrollee: be === role)
    pe.set(role: nil)
    expect(pe).to have_attributes(enrollee_type: "NilClass", enrollee: nil)
  end

  it_behaves_like "has a timestamp predicate", "approved_at", "ever_approved", :"approved=" do
    let(:instance) { Suma::Fixtures.program_enrollment.instance }
  end

  it_behaves_like "has a timestamp predicate", "unenrolled_at", "unenrolled" do
    let(:instance) { Suma::Fixtures.program_enrollment.instance }
  end

  it "has accessors describing its enrollment condition" do
    pe = Suma::Fixtures.program_enrollment.unapproved.instance
    expect(pe).to have_attributes(
      ever_approved?: false,
      enrolled?: false,
      unenrolled?: false,
      enrollment_status: :pending,
    )
    pe.approved = true
    expect(pe).to have_attributes(
      ever_approved?: true,
      enrolled?: true,
      unenrolled?: false,
      enrollment_status: :enrolled,
    )
    pe.unenrolled = true
    expect(pe).to have_attributes(
      ever_approved?: true,
      enrolled?: false,
      unenrolled?: true,
      enrollment_status: :unenrolled,
    )
  end
end
