# frozen_string_literal: true

require "suma/postgres/model"
require "suma/admin_linked"

class Suma::Program::Enrollment < Suma::Postgres::Model(:program_enrollments)
  include Suma::AdminLinked

  many_to_one :program, class: "Suma::Program"
  many_to_one :member, class: "Suma::Member"
  many_to_one :role, class: "Suma::Role"
  many_to_one :organization, class: "Suma::Organization"
  many_to_one :approved_by, class: "Suma::Member"
  many_to_one :unenrolled_by, class: "Suma::Member"

  dataset_module do
    def enrolled(as_of:)
      return self.
          # Approved at some point before now
          where(Sequel[:approved_at] <= as_of).
          # Never unenrolled, or unenrolled in the future
          where(Sequel[unenrolled_at: nil] | (Sequel[:unenrolled_at] > as_of))
    end

    def active(as_of:) = self.where(program: Suma::Program.dataset.active(as_of:)).enrolled(as_of:)

    def for_members(member)
      verified_org_ids = Suma::Organization::Membership.
        verified.
        where(member:).
        select(:verified_organization_id)
      ds = self.where(
        Sequel[member:] |
        Sequel[organization_id: verified_org_ids] |
          Sequel[role: Suma::Role.dataset.where(members: member)],
      )
      ds = ds.
        left_join(
          :organization_memberships,
          {verified_organization_id: Sequel[:program_enrollments][:organization_id]},
        ).left_join(
          :roles_members,
          {role_id: Sequel[:program_enrollments][:role_id]},
        ).select(
          Sequel[:program_enrollments][Sequel.lit("*")],
          Sequel.function(
            :coalesce,
            Sequel[:program_enrollments][:member_id],
            Sequel[:organization_memberships][:member_id],
            Sequel[:roles_members][:member_id],
          ).as(:annotated_member_id),
        )
      return ds
    end
  end

  def program_active_at?(t)
    return self.program.period.cover?(t)
  end

  def approved?
    return self.approved_at ? true : false
  end

  def approved=(v)
    self.approved_at = v ? Time.now : nil
  end

  def unenrolled?
    return self.unenrolled_at ? true : false
  end

  def unenrolled=(v)
    self.unenrolled_at = v ? Time.now : nil
  end

  # @return [Suma::Member,Suma::Organization,Suma::Role]
  def enrollee = self.member || self.organization || self.role

  def enrollee_type = self.enrollee.class.name.demodulize

  def rel_admin_link = "/program-enrollment/#{self.id}"
end

# Table: program_enrollments
# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Columns:
#  id               | integer                  | PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY
#  created_at       | timestamp with time zone | NOT NULL DEFAULT now()
#  updated_at       | timestamp with time zone |
#  program_id       | integer                  | NOT NULL
#  member_id        | integer                  |
#  organization_id  | integer                  |
#  approved_at      | timestamp with time zone |
#  approved_by_id   | integer                  |
#  unenrolled_at    | timestamp with time zone |
#  unenrolled_by_id | integer                  |
#  role_id          | integer                  |
# Indexes:
#  program_enrollments_pkey                  | PRIMARY KEY btree (id)
#  unique_enrollee_in_program_idx            | UNIQUE btree (COALESCE(member_id, 0), COALESCE(organization_id, 0), COALESCE(role_id, 0), program_id)
#  program_enrollments_approved_at_index     | btree (approved_at)
#  program_enrollments_member_id_index       | btree (member_id)
#  program_enrollments_organization_id_index | btree (organization_id)
#  program_enrollments_program_id_index      | btree (program_id)
#  program_enrollments_role_id_index         | btree (role_id)
#  program_enrollments_unenrolled_at_index   | btree (unenrolled_at)
# Check constraints:
#  one_enrollee_set | (member_id IS NOT NULL AND organization_id IS NULL AND role_id IS NULL OR member_id IS NULL AND organization_id IS NOT NULL AND role_id IS NULL OR member_id IS NULL AND organization_id IS NULL AND role_id IS NOT NULL)
# Foreign key constraints:
#  program_enrollments_approved_by_id_fkey   | (approved_by_id) REFERENCES members(id) ON DELETE SET NULL
#  program_enrollments_member_id_fkey        | (member_id) REFERENCES members(id) ON DELETE CASCADE
#  program_enrollments_organization_id_fkey  | (organization_id) REFERENCES organizations(id) ON DELETE CASCADE
#  program_enrollments_program_id_fkey       | (program_id) REFERENCES programs(id) ON DELETE CASCADE
#  program_enrollments_role_id_fkey          | (role_id) REFERENCES roles(id) ON DELETE CASCADE
#  program_enrollments_unenrolled_by_id_fkey | (unenrolled_by_id) REFERENCES members(id) ON DELETE SET NULL
# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
