# frozen_string_literal: true

require "suma/postgres/model"

class Suma::Organization < Suma::Postgres::Model(:organizations)
  plugin :timestamps

  def before_create
    self.slug ||= Suma.to_slug(self.name)
  end
end

# Table: organizations
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Columns:
#  id         | integer                  | PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY
#  created_at | timestamp with time zone | NOT NULL DEFAULT now()
#  updated_at | timestamp with time zone |
#  name       | text                     | NOT NULL
#  slug       | text                     | NOT NULL
# Indexes:
#  organizations_pkey | PRIMARY KEY btree (id)
# Referenced By:
#  vendors                                 | vendors_organization_id_fkey                                 | (organization_id) REFERENCES organizations(id) ON DELETE CASCADE
#  vendor_service_organization_constraints | vendor_service_organization_constraints_organization_id_fkey | (organization_id) REFERENCES organizations(id) ON DELETE CASCADE
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------
