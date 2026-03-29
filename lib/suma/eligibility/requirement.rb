# frozen_string_literal: true

require "suma/eligibility"
require "suma/postgres/model"

class Suma::Eligibility::Requirement < Suma::Postgres::Model(:eligibility_requirements)
  include Suma::AdminLinked
  include Suma::Postgres::HybridSearch

  plugin :hybrid_search
  plugin :timestamps

  many_to_one :created_by, class: "Suma::Member"

  many_to_one :expression, class: "Suma::Eligibility::Expression"

  many_to_many :programs,
               class: "Suma::Program",
               join_table: :eligibility_requirements_programs,
               left_key: :requirement_id,
               right_key: :program_id,
               order: order_desc
  many_to_many :payment_triggers,
               class: "Suma::Payment::Trigger",
               join_table: :eligibility_requirements_payment_triggers,
               left_key: :requirement_id,
               right_key: :payment_trigger_id,
               order: order_desc

  def all_resources = self.programs + self.payment_triggers

  # Replace an expression with a serialized version (usually from an endpoint).
  # If the serialized version is the same as the current serialized expression, noop.
  # Otherwise, delete the current expression (and all children)
  # and replace it with a newly created tree from the serialized version.
  # @param serialized [Hash]
  def replace_expression(serialized)
    existing = self.expression.serialize
    return if existing == serialized
    self.db.transaction do
      # Since expression_id is non-nullable, we need to create and assign before destroying.
      new_expr = Suma::Eligibility::Expression.deserialize(serialized)
      old_expr = self.expression
      self.update(expression: new_expr)
      old_expr.destroy
    end
  end

  def rel_admin_link = "/eligibility-requirement/#{self.id}"

  def hybrid_search_fields
    return [
      :cached_expression_string,
      ["Programs", self.programs.map(&:name)],
      ["Payment Triggers", self.payment_triggers.map(&:label)],
    ]
  end

  def before_create
    self.expression ||= Suma::Eligibility::Expression.create_empty
    self.created_by = Suma.request_user_and_admin[1]
    self.cached_expression_string = self.expression.to_formula_str
    self.cached_attribute_ids = self.expression.referenced_attributes.map(&:id)
    super
  end

  def before_update
    if (expr = self.associations[:expression])
      # Only rebuild the cache if expressions have been loaded
      self.cached_expression_string = expr.to_formula_str
      self.cached_attribute_ids = expr.referenced_attributes.map(&:id)
    end
    super
  end
end
