# frozen_string_literal: true

require "suma/postgres/model"
require "suma/admin_linked"

class Suma::Program::EnrollmentExclusion < Suma::Postgres::Model(:program_enrollment_exclusions)
  include Suma::AdminLinked

  plugin :timestamps

  many_to_one :program, class: "Suma::Program"
  many_to_one :member, class: "Suma::Member"
  many_to_one :role, class: "Suma::Role"
  many_to_one :created_by, class: "Suma::Member"

  # @return [Suma::Member,Suma::Role]
  def enrollee = self.member || self.role

  # @return ["Member","Role","NilClass"]
  def enrollee_type = self.enrollee.class.name.demodulize

  def rel_admin_link = "/program-enrollment-exclusion/#{self.id}"
end
