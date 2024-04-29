# frozen_string_literal: true

require "suma/postgres/model"
require "suma/admin_linked"

class Suma::Organization < Suma::Postgres::Model(:organizations)
  include Suma::AdminLinked
  plugin :timestamps

  one_to_many :memberships, class: "Suma::Organization::Membership"
  one_to_many :verified_memberships,
              class: "Suma::Organization::Membership",
              conditions: {unverified_member_id: nil},
              readonly: true
  one_to_many :unverified_memberships,
              class: "Suma::Organization::Membership",
              conditions: {verified_member_id: nil},
              readonly: true

  def rel_admin_link = "/organization/#{self.id}"
end
