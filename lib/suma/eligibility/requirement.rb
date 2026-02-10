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

  many_to_one :program, class: "Suma::Program"
  many_to_one :payment_trigger, class: "Suma::Payment::Trigger"
  RESOURCE_ASSOCIATIONS = [:program, :payment_trigger].freeze

  dataset_module do
    # @param resource [Suma::Eligibility::Resource::InstanceMethods]
    def for_resource(resource)
      conds = resource.requirement_where_condition
      return self.where(conds)
    end
  end

  def resource = self.unambiguous_association(RESOURCE_ASSOCIATIONS)

  def resource=(o)
    self.set_ambiguous_association(RESOURCE_ASSOCIATIONS, o)
  end

  def resource_label
    r = self.resource
    return r.name.en if r.is_a?(Suma::Program)
    return r.label
  end

  def rel_admin_link = "/eligibility-requirement/#{self.id}"

  def before_create
    self.expression ||= Suma::Eligibility::Expression.create
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
