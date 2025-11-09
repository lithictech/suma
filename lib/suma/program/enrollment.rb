# frozen_string_literal: true

require "suma/postgres/model"
require "suma/admin_linked"

class Suma::Program::Enrollment < Suma::Postgres::Model(:program_enrollments)
  include Suma::AdminLinked
  include Suma::Postgres::HybridSearch

  plugin :hybrid_search
  plugin :timestamps

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

    def for_members(members)
      # To find the enrollments for some members, and track the enrollment back to a member,
      # we need to assemble a big set of JOINs. For example, we need to know what member id is related
      # to a program enrollment, based on the enrollment->role->organization role->organization->membership->member.
      # See also: Member combined_program_enrollments dataset, which is able to do this with a UNION instead
      # so is significantly simpler (since that doesn't need to relate things back to a user).
      verified_org_ids = Suma::Organization::Membership.
        verified.
        where(member: members).
        select(:verified_organization_id)
      member_ids = members.is_a?(Array) ? members.map(&:id) : members.select(:id)
      full = self.
        left_join(
          self.db[:roles_members].
            where(member_id: member_ids).
            as(:jrolemembers),
          {role_id: Sequel[:program_enrollments][:role_id]},
        ).left_join(
          self.db[:roles_organizations].
            where(organization_id: verified_org_ids).
            left_join(
              self.db[:organization_memberships],
              {verified_organization_id: Sequel[:roles_organizations][:organization_id]},
            ).as(:jroleorgs),
          {role_id: Sequel[:program_enrollments][:role_id]},
        ).left_join(
          self.db[:organization_memberships].
            where(verified_organization_id: verified_org_ids).
            as(:jorgmembers),
          {verified_organization_id: Sequel[:program_enrollments][:organization_id]},
        )
      coalesce_member_id = Sequel.function(
        :coalesce,
        Sequel[:program_enrollments][:member_id],
        Sequel[:jorgmembers][:member_id],
        Sequel[:jrolemembers][:member_id],
        Sequel[:jroleorgs][:member_id],
      )
      annotated = full.reselect.select_append(coalesce_member_id.as(:annotated_member_id))
      annotated = annotated.exclude(
        self.db[:program_enrollment_exclusions].where(
          Sequel[program_id: :program_id] &
          (
            Sequel[member_id: coalesce_member_id] |
            Sequel[role_id: self.db[:roles_members].where(member_id: coalesce_member_id).select(:role_id)]
          ),
        ).exists,
      )
      limited = annotated.where(coalesce_member_id => member_ids)
      return limited
    end
  end

  # Return true if the given time is within the program's period.
  def program_active_at?(t)
    return self.program.period.cover?(t)
  end

  # Return true if this enrollment has ever been approved (approved_at is set).
  def ever_approved? = Suma::MethodUtilities.timestamp_set?(self, :approved_at)

  # Return true if the enrollment is approved and not unenrolled.
  def enrolled? = self.ever_approved? && !self.unenrolled?

  # Set approved_at.
  def approved=(v)
    Suma::MethodUtilities.timestamp_set(self, :approved_at, v)
  end

  # Return true if unenrolled_at is set.
  def unenrolled?
    Suma::MethodUtilities.timestamp_set?(self, :unenrolled_at)
  end

  # Set unenrolled_at.
  def unenrolled=(v)
    Suma::MethodUtilities.timestamp_set(self, :unenrolled_at, v)
  end

  # @return [Suma::Member,Suma::Organization,Suma::Role]
  def enrollee = self.member || self.organization || self.role

  # @return ["Member","Organization","Role","NilClass"]
  def enrollee_type = self.enrollee.class.name.demodulize

  def enrollment_status
    return :enrolled if self.enrolled?
    return :unenrolled if self.unenrolled?
    return :pending
  end

  # Return the unique enrolled members for this enrollment.
  # Look them up through direct membership, organization, and roles.
  def members
    return [self.member] if self.member
    return self.organization.memberships.map(&:member) if self.organization
    result = self.role.members + self.role.organizations.flat_map(&:memberships).map(&:member)
    return result.uniq
  end

  def rel_admin_link = "/program-enrollment/#{self.id}"

  def hybrid_search_fields
    return [
      :program,
      :enrollee,
      :enrollee_type,
      :enrollment_status,
    ]
  end
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
#  search_content   | text                     |
#  search_embedding | vector(384)              |
#  search_hash      | text                     |
# Indexes:
#  program_enrollments_pkey                          | PRIMARY KEY btree (id)
#  unique_enrollee_in_program_idx                    | UNIQUE btree (COALESCE(member_id, 0), COALESCE(organization_id, 0), COALESCE(role_id, 0), program_id)
#  program_enrollments_approved_at_index             | btree (approved_at)
#  program_enrollments_member_id_index               | btree (member_id)
#  program_enrollments_organization_id_index         | btree (organization_id)
#  program_enrollments_program_id_index              | btree (program_id)
#  program_enrollments_role_id_index                 | btree (role_id)
#  program_enrollments_search_content_trigram_index  | gist (search_content)
#  program_enrollments_search_content_tsvector_index | gin (to_tsvector('english'::regconfig, search_content))
#  program_enrollments_unenrolled_at_index           | btree (unenrolled_at)
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
