# frozen_string_literal: true

require "suma/eligibility"
require "suma/postgres/model"

# This is a very large view since it is a subset of combinatorial across access (member, role, org, org role)
# and attributes. That is, if Role X has Attributes Y and Z, and Member A and B have Role X,
# then we end up with rows for:
# - Member A/Attribute Y
# - Member A/Attribute Z
# - Member B/Attribute Y
# - Member B/Attribute Z
#
# Duplicate rows are collapsed (members could have multiple ways attributes are assigned).
#
class Suma::Eligibility::MemberAssignment < Suma::Postgres::Model(:eligibility_member_assignments)
  many_to_one :attribute, class: "Suma::Eligibility::Attribute"
  many_to_one :member, class: "Suma::Member"

  MEMBER = "member"
  ROLE = "role"
  MEMBERSHIP = "membership"
  ORGANIZATION_ROLE = "organization_role"

  # Given the source_type and source_ids, return the actual models/rows that specify
  # where this attribute came from.
  def to_sources
    return case self.source_type
      when MEMBER
        [self.member]
      when ROLE
        [Suma::Role[self.source_ids[0]]]
      when MEMBERSHIP
        [Suma::Organization::Membership[self.source_ids[0]]]
      when ORGANIZATION_ROLE
        [
          Suma::Organization[self.source_ids[0]],
          Suma::Role[self.source_ids[1]],
        ]
      else
        raise Suma::InvariantViolation, "unexpected source type: #{self.inspect}"
    end
  end
end
