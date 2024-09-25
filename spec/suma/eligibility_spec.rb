# frozen_string_literal: true

RSpec.describe "Suma::Eligibility", :db do
  let(:described_class) { Suma::Eligibility }

  it "can create constraints for offerings" do
    e = Suma::Fixtures.eligibility_constraint.create
    o = Suma::Fixtures.offering.create
    o.add_eligibility_constraint(e)
    o.remove_eligibility_constraint(e)
  end

  describe "for members" do
    let(:e) { Suma::Fixtures.eligibility_constraint.create }
    let(:o) { Suma::Fixtures.member.create }

    it "cannot have multiple member ids within the same row" do
      expect do
        o.db[:eligibility_member_associations].insert(
          constraint_id: e.id,
          verified_member_id: o.id,
          rejected_member_id: o.id,
        )
      end.to raise_error(/one_member_set/)
    end

    it "cannot have the same member for multiple rows with the same constraint" do
      expect do
        o.db[:eligibility_member_associations].insert(
          constraint_id: e.id,
          verified_member_id: o.id,
        )
        o.db[:eligibility_member_associations].insert(
          constraint_id: e.id,
          rejected_member_id: o.id,
        )
      end.to raise_error(/duplicate key value violates unique constraint "unique_member"/)
    end

    it "can manage constraints for members" do
      o.replace_eligibility_constraint(e, :verified)
      expect(o).to have_attributes(
        verified_eligibility_constraints: contain_exactly(be === e),
        pending_eligibility_constraints: [],
        rejected_eligibility_constraints: [],
      )

      o.replace_eligibility_constraint(e, :pending)
      expect(o).to have_attributes(
        verified_eligibility_constraints: [],
        pending_eligibility_constraints: contain_exactly(be === e),
        rejected_eligibility_constraints: [],
      )

      o.replace_eligibility_constraint(e, :rejected)
      expect(o).to have_attributes(
        verified_eligibility_constraints: [],
        pending_eligibility_constraints: [],
        rejected_eligibility_constraints: contain_exactly(be === e),
      )
    end
  end

  describe "Constraint" do
    describe "assign_to_admins" do
      it "assigns the constraint to only admins" do
        admin = Suma::Fixtures.member.admin.create
        member = Suma::Fixtures.member.create
        Suma::Fixtures.eligibility_constraint.create
        Suma::Eligibility::Constraint.assign_to_admins
        expect(admin.refresh.eligibility_constraints_with_status).to have_length(1)
        expect(member.refresh.eligibility_constraints_with_status).to be_empty
      end
    end
  end
end
