# frozen_string_literal: true

require "suma/postgres/model"
require "suma/admin_linked"

class Suma::Program::EnrollmentExclusion < Suma::Postgres::Model(:program_enrollment_exclusions)
  include Suma::AdminLinked

  plugin :timestamps

  many_to_one :program, class: "Suma::Program"
  many_to_one :member, class: "Suma::Member"
  many_to_one :created_by, class: "Suma::Member"

  def rel_admin_link = "/program-enrollment-exclusion/#{self.id}"
end
