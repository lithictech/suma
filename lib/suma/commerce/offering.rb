# frozen_string_literal: true

require "suma/commerce"
require "suma/image"
require "suma/postgres/model"

class Suma::Commerce::Offering < Suma::Postgres::Model(:commerce_offerings)
  include Suma::Image::AssociatedMixin

  plugin :timestamps
  plugin :tstzrange_fields, :period

  dataset_module do
    def available_at(t)
      return self.where(Sequel.pg_range(:period).contains(Sequel.cast(t, :timestamptz)))
    end
  end
end
