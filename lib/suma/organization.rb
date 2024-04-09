# frozen_string_literal: true

require "suma/postgres/model"
require "suma/admin_linked"

class Suma::Organization < Suma::Postgres::Model(:organizations)
  include Suma::AdminLinked
  plugin :timestamps

  one_to_many :memberships, class: "Suma::Organization::Membership"

  def self.supported_organizations = self.all.map(&:name)

  def rel_admin_link = "/organization/#{self.id}"
end
