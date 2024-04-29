# frozen_string_literal: true

require "suma/postgres/model"
require "suma/admin_linked"

class Suma::Organization < Suma::Postgres::Model(:organizations)
  include Suma::AdminLinked
  plugin :timestamps

  one_to_many :memberships, class: "Suma::Organization::Membership", key: :verified_organization_id

  def rel_admin_link = "/organization/#{self.id}"
end
