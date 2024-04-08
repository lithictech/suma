# frozen_string_literal: true

require "suma/postgres/model"

class Suma::Organization < Suma::Postgres::Model(:organizations)
  plugin :timestamps

  one_to_many :memberships, class: "Suma::Organization::Membership"
end
