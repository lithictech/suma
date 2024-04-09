# frozen_string_literal: true

require "suma/postgres/model"

class Suma::Organization < Suma::Postgres::Model(:organizations)
  plugin :timestamps

  one_to_many :memberships, class: "Suma::Organization::Membership"

  def self.supported_organizations = self.all.map(&:name)
end
