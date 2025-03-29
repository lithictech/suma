# frozen_string_literal: true

require "suma/postgres/model"
require "suma/admin_linked"

class Suma::Organization::Membership < Suma::Postgres::Model(:organization_memberships)
  include Suma::AdminLinked
  include Suma::Postgres::HybridSearch

  plugin :hybrid_search
  plugin :timestamps

  many_to_one :verified_organization, class: "Suma::Organization"
  many_to_one :member, class: "Suma::Member"

  dataset_module do
    def verified = self.exclude(verified_organization_id: nil)
  end

  def verified? = !self.verified_organization.nil?
  def unverified? = !self.verified?

  def verified_organization_id=(id)
    self.unverified_organization_name = nil unless id.nil?
    self[:verified_organization_id] = id
  end

  def rel_admin_link = "/membership/#{self.id}"

  def hybrid_search_fields
    return [
      self.verified? && :verified_organization,
      self.unverified? && :unverified_organization_name,
      :member,
    ]
  end

  def hybrid_search_facts
    return [
      self.verified? && "I am verified.",
      self.unverified? && "I am unverified.",
    ]
  end
end

# Table: organization_memberships
# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Columns:
#  id                           | integer                  | PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY
#  created_at                   | timestamp with time zone | NOT NULL DEFAULT now()
#  updated_at                   | timestamp with time zone |
#  verified_organization_id     | integer                  |
#  unverified_organization_name | text                     |
#  member_id                    | integer                  |
# Indexes:
#  organization_memberships_pkey                           | PRIMARY KEY btree (id)
#  unique_member_membership_in_verified_organization       | UNIQUE btree (member_id, verified_organization_id)
#  organization_memberships_member_id_index                | btree (member_id)
#  organization_memberships_verified_organization_id_index | btree (verified_organization_id)
# Check constraints:
#  unambiguous_verification_status | (verified_organization_id IS NOT NULL AND unverified_organization_name IS NULL OR verified_organization_id IS NULL AND unverified_organization_name IS NOT NULL)
# Foreign key constraints:
#  organization_memberships_member_id_fkey                | (member_id) REFERENCES members(id)
#  organization_memberships_verified_organization_id_fkey | (verified_organization_id) REFERENCES organizations(id)
# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
