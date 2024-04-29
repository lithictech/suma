# frozen_string_literal: true

require "suma/postgres/model"
require "suma/admin_linked"

class Suma::Organization::Membership < Suma::Postgres::Model(:organization_memberships)
  include Suma::AdminLinked
  plugin :timestamps

  many_to_one :verified_organization, class: "Suma::Organization"
  many_to_one :member, class: "Suma::Member"

  def verified? = !self.verified_organization.nil?
  def unverified? = !self.verified?

  def rel_admin_link = "/membership/#{self.id}"
end
