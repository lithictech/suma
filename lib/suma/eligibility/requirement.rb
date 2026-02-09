# frozen_string_literal: true

require "suma/eligibility"
require "suma/postgres/model"

class Suma::Eligibility::Requirement < Suma::Postgres::Model(:eligibility_requirements)
  include Suma::Postgres::HybridSearch

  plugin :hybrid_search
  plugin :timestamps

  many_to_one :created_by, class: "Suma::Member"

  many_to_one :expression, class: "Suma::Eligibility::Expression"

  many_to_one :program, class: "Suma::Program"
  many_to_one :payment_trigger, class: "Suma::Payment::Trigger"
  RESOURCE_ASSOCIATIONS = [:program, :payment_trigger].freeze

  dataset_module do
    def for_resource(resource)
      conds = case resource
        when Suma::Payment::Trigger
          {payment_trigger_id: resource.id}
        when Suma::Program
          {program_id: resource.id}
        else
          raise TypeError("requirements not supported for #{resource.class}")
      end
      return self.where(conds)
    end
  end

  def resource = Suma::MethodUtilities.unambiguous_association(self, RESOURCE_ASSOCIATIONS)

  def resource=(o)
    Suma::MethodUtilities.set_ambiguous_association(self, RESOURCE_ASSOCIATIONS, o)
  end

  def before_create
    self.expression ||= Suma::Eligibility::Expression.create
    self.created_by = Suma.request_user_and_admin[1]
    super
  end
end
