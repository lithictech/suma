# frozen_string_literal: true

require "suma/postgres/model"

class Suma::SupportedGeography < Suma::Postgres::Model(:supported_geographies)
  many_to_one :parent, class: self
end
