# frozen_string_literal: true

require "suma/postgres/model"

class Suma::Role < Suma::Postgres::Model(:roles)
  include Suma::AdminLinked

  def self.admin_role
    return Suma.cached_get("role_admin") do
      self.find_or_create_or_find(name: "admin")
    end
  end

  def self.upload_files_role
    return Suma.cached_get("role_upload_files") do
      Suma::Role.find_or_create_or_find(name: "upload_files")
    end
  end

  many_to_many :members,
               class: "Suma::Member",
               join_table: :roles_members

  def rel_admin_link = "/role/#{self.id}"
end

# Table: roles
# ----------------------------------------------------------------------------
# Columns:
#  id   | integer | PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY
#  name | text    | NOT NULL
# Indexes:
#  roles_pkey     | PRIMARY KEY btree (id)
#  roles_name_key | UNIQUE btree (name)
# Referenced By:
#  roles_members | roles_members_role_id_fkey | (role_id) REFERENCES roles(id)
# ----------------------------------------------------------------------------
