# frozen_string_literal: true

require "suma/postgres/model"
require "suma/admin_linked"

class Suma::Organization::Membership < Suma::Postgres::Model(:organization_memberships)
  include Suma::AdminLinked
  plugin :timestamps

  many_to_one :organization, key: :organization_id, class: "Suma::Organization"
  many_to_one :member, class: "Suma::Member"

  def rel_admin_link = "/membership/#{self.id}"
end
