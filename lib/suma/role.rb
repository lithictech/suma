# frozen_string_literal: true

require "suma/postgres/model"

class Suma::Role < Suma::Postgres::Model(:roles)
  include Suma::AdminLinked

  class Cache
    # :section: App Roles

    # Can use the POST /v1/images endpoint to upload files.
    def upload_files = get("upload_files")

    # :section: Admin Roles

    # Can access the FULL suite of admin capabilities.
    def admin = get("admin")

    # Can modify admin member information, and view non-privileged areas of admin.
    def onboarding_manager = get("onboarding_manager")

    # Can read, but not write, all of admin.
    # Mostly used for testing purposes but could also be used to give people readonly access.
    def readonly_admin = get("admin_readonly")

    # Used only for testing. Has access to admin but not resources.
    def noop_admin = get("admin_noop")

    def get(name)
      name = name.to_s if name.is_a?(Symbol)
      return Suma.cached_get("role_#{name}") do
        Suma::Role.find_or_create_or_find(name:)
      end
    end
  end

  class << self
    # Return a cache of roles lookups.
    # Generally callers should use +Suma::Member::RoleAccess+ rather than look at roles directly.
    def cache = @cache ||= Cache.new
  end

  many_to_many :members,
               class: "Suma::Member",
               join_table: :roles_members

  one_to_many :program_enrollments, class: "Suma::Program::Enrollment"

  def rel_admin_link = "/role/#{self.id}"

  def label = self.name.titleize
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
