# frozen_string_literal: true

require "suma/eligibility"
require "suma/postgres/model"

class Suma::Eligibility::Requirement < Suma::Postgres::Model(:eligibility_requirements)
  many_to_one :program, class: "Suma::Program"
  many_to_one :payment_trigger, class: "Suma::Payment::Trigger"

  many_to_one :expression, class: "Suma::Eligibility::Expression"

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

  def before_create
    self.expression ||= Suma::Eligibility::Expression.create
    super
  end
end
