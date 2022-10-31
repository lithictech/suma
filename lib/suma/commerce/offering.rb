# frozen_string_literal: true

require "suma/postgres"
require "suma/postgres/model"

class Suma::Commerce::Offerings < Suma::Postgres::Model(:commerce_offerings)
  plugin :timestamps
  plugin :tstzrange_fields, :period

  dataset_module do
    def available
      # TODO: add timerange criteria
      return self.all
    end
  end
end
