# frozen_string_literal: true

require "suma/postgres/model"
require "suma/admin_linked"

class Suma::Organization::Membership < Suma::Postgres::Model(:organization_memberships)
  include Suma::AdminLinked
  plugin :timestamps

  many_to_one :organization, class: "Suma::Organization"
  many_to_one :verified_member, class: "Suma::Member"
  many_to_one :unverified_member, class: "Suma::Member"

  def member = self.verified_member || self.unverified_member

  def rel_admin_link = "/membership/#{self.id}"
end
