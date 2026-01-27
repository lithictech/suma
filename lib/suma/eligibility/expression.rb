# frozen_string_literal: true

require "suma/eligibility"
require "suma/postgres/model"

class Suma::Eligibility::Expression < Suma::Postgres::Model(:eligibility_expressions)
  many_to_one :left, class: self
  many_to_one :right, class: self
  many_to_one :attribute, class: "Suma::Eligibility::Attribute"

  LEAF = :leaf
  BRANCH = :branch

  def type = self.attribute_id ? LEAF : BRANCH
  def leaf? = self.type == LEAF
  def branch? = self.type == BRANCH

  def ruby_operator = self.operator == "OR" ? :| : :&
end
