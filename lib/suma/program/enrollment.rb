# frozen_string_literal: true

require "suma/postgres/model"
require "suma/admin_linked"

class Suma::Program::Enrollment < Suma::Postgres::Model(:program_enrollments)
  include Suma::AdminLinked

  many_to_one :program, class: "Suma::Program"
  many_to_one :member, class: "Suma::Member"
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

    def for_member(member)
      verified_org_ids = Suma::Organization::Membership.
        verified.
        where(member:).
        select(:verified_organization_id)
      ds = self.where(Sequel[member:] | Sequel[organization_id: verified_org_ids])
      ds = ds.
        left_join(:organization_memberships, {verified_organization_id: :organization_id}).
        select(
          Sequel[:program_enrollments][Sequel.lit("*")],
          Sequel.function(
            :coalesce,
            Sequel[:program_enrollments][:member_id],
            Sequel[:organization_memberships][:member_id],
          ).as(:actual_member_id),
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

  # @return [Suma::Member,Suma::Organization]
  def enrollee = self.member || self.organization

  def rel_admin_link = "/program-enrollment/#{self.id}"
end
