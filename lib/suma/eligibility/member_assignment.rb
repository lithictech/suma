# frozen_string_literal: true

require "suma/eligibility"
require "suma/postgres/model"

class Suma::Eligibility::MemberAssignment < Suma::Postgres::Model(:eligibility_member_assignments)
  many_to_one :attribute, class: "Suma::Eligibility::Attribute"
  many_to_one :member, class: "Suma::Member"

  # Given the source_type and source_ids, return the actual models/rows that specify
  # where this attribute came from.
  def to_sources
    return case self.source_type
      when "member"
        [self.member]
      when "role"
        [Suma::Role[self.source_ids[0]]]
      when "membership"
        [Suma::Organization::Membership[self.source_ids[0]]]
      when "organization_role"
        [
          Suma::Organization[self.source_ids[0]],
          Suma::Role[self.source_ids[1]],
        ]
      else
        raise Suma::InvariantViolation, "unexpected source type: #{self.inspect}"
    end
  end
end
