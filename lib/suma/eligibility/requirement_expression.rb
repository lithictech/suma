# frozen_string_literal: true

require "suma/eligibility"
require "suma/postgres/model"

class Suma::Eligibility::RequirementExpression < Suma::Postgres::Model(:eligibility_requirement_expressions)
  many_to_one :left, class: self
  many_to_one :right, class: self
  many_to_one :attribute, class: "Suma::Eligibility::Attribute"
end
