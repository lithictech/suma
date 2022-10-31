# frozen_string_literal: true

require "suma/commerce"
require "suma/postgres"
require "suma/postgres/model"

class Suma::Commerce::Offering < Suma::Postgres::Model(:commerce_offerings)
  plugin :timestamps
  plugin :tstzrange_fields, :period

  dataset_module do
    def available_at(t)
      # +contains+ only compares time range format
      t_range = Sequel::Postgres::PGRange.new(t, t)
      return self.where(Sequel.pg_range(:period).contains(t_range))
    end
  end
end
