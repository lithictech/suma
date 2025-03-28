# frozen_string_literal: true

require "suma/postgres/model"
require "suma/admin_linked"

class Suma::Organization < Suma::Postgres::Model(:organizations)
  include Suma::Postgres::HybridSearchHelpers
  include Suma::AdminLinked

  plugin :hybrid_searchable
  plugin :timestamps

  one_to_many :memberships, class: "Suma::Organization::Membership", key: :verified_organization_id
  one_to_many :program_enrollments, class: "Suma::Program::Enrollment"

  def rel_admin_link = "/organization/#{self.id}"

  def hybrid_search_fields
    return [
      :name,
    ]
  end
end

# Table: organizations
# -----------------------------------------------------------------------------------------------------------------------------------------------------
# Columns:
#  id         | integer                  | PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY
#  created_at | timestamp with time zone | NOT NULL DEFAULT now()
#  updated_at | timestamp with time zone |
#  name       | text                     | NOT NULL
# Indexes:
#  organizations_pkey     | PRIMARY KEY btree (id)
#  organizations_name_key | UNIQUE btree (name)
# Referenced By:
#  organization_memberships | organization_memberships_verified_organization_id_fkey | (verified_organization_id) REFERENCES organizations(id)
#  program_enrollments      | program_enrollments_organization_id_fkey               | (organization_id) REFERENCES organizations(id) ON DELETE CASCADE
# -----------------------------------------------------------------------------------------------------------------------------------------------------
