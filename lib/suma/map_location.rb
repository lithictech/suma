# frozen_string_literal: true

require "suma/postgres/model"

class Suma::MapLocation < Suma::Postgres::Model(:map_locations)
  many_to_many :commerce_offerings,
               class: "Suma::Commerce::Offering",
               join_table: :map_locations_commerce_offerings,
               right_key: :offering_id
end
