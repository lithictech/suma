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
  set_primary_key [:member_id, :attribute_id, :source_type, :source_member_id, :source_role_id, :source_membership_id]
  class << self
    def read_only? = true
  end

  many_to_one :attribute, class: "Suma::Eligibility::Attribute"
  many_to_one :member, class: "Suma::Member"

  many_to_one :source_member, class: "Suma::Member"
  many_to_one :source_membership, class: "Suma::Organization::Membership"
  many_to_one :source_role, class: "Suma::Role"

  MEMBER = "member"
  ROLE = "role"
  MEMBERSHIP = "membership"
  ORGANIZATION_ROLE = "organization_role"

  def unique_key = "#{self.member_id}.#{self.attribute_id}.#{self.source_type}.#{self.sources.map(&:id).join('_')}"

  # Given the source_type and source ids, return the actual models/rows that specify
  # where this attribute came from.
  def sources
    return case self.source_type
      when MEMBER
        [self.source_member]
      when ROLE
        [self.source_role]
      when MEMBERSHIP
        [self.source_membership]
      when ORGANIZATION_ROLE
        [
          self.source_membership,
          self.source_role,
        ]
      else
        # :nocov:
        raise Suma::InvariantViolation, "unexpected source type: #{self.inspect}"
      # :nocov:
    end
  end
end

# Table: eligibility_member_assignments
# -----------------------------------------------------------------------------------------------------------
# Primary Key: (member_id, attribute_id, source_type, source_member_id, source_role_id, source_membership_id)
# Columns:
#  member_id            | integer |
#  attribute_id         | integer |
#  depth                | integer |
#  source_type          | text    |
#  source_member_id     | integer |
#  source_role_id       | integer |
#  source_membership_id | integer |
# -----------------------------------------------------------------------------------------------------------
