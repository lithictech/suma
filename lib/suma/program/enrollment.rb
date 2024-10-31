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
