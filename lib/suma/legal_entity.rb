# frozen_string_literal: true

require "suma/postgres/model"

class Suma::LegalEntity < Suma::Postgres::Model(:legal_entities)
  many_to_one :address, class: "Suma::Address"
  one_to_one :customer, class: "Suma::Customer"
end
