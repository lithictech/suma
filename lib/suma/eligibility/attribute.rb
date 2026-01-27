# frozen_string_literal: true

require "suma/eligibility"
require "suma/postgres/model"

class Suma::Eligibility::Attribute < Suma::Postgres::Model(:eligibility_attributes)
  many_to_one :parent, class: self
end
