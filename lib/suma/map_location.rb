# frozen_string_literal: true

require "suma/postgres/model"

class Suma::MapLocation < Suma::Postgres::Model(:map_locations)
  many_to_many :commerce_offerings,
               class: "Suma::Commerce::Offering",
               join_table: :map_locations_commerce_offerings,
               right_key: :offering_id

  class << self
    def search_expr(min_lat:, min_lng:, max_lat:, max_lng:, lat_col: :lat, lng_col: :lng)
      return (Sequel[lat_col] >= min_lat) &
          (Sequel[lat_col] <= max_lat) &
          (Sequel[lng_col] >= min_lng) &
          (Sequel[lng_col] <= max_lng)
    end
  end

  dataset_module do
    def search(min_lat:, min_lng:, max_lat:, max_lng:)
      return self.where(Suma::MapLocation.search_expr(min_lat:, min_lng:, max_lat:, max_lng:))
    end
  end
end
