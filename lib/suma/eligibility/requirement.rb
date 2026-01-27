# frozen_string_literal: true

require "suma/eligibility"
require "suma/postgres/model"

class Suma::Eligibility::Requirement < Suma::Postgres::Model(:eligibility_requirements)
  many_to_one :commerce_offering, class: "Suma::Commerce::Offering"
  many_to_one :vendor_configuration, class: "Suma::AnonProxy::VendorConfiguration"
  many_to_one :payment_trigger, class: "Suma::Payment::Trigger"

  many_to_one :expression, class: "Suma::Eligibility::RequirementExpression"

  def before_create
    self.expression ||= Suma::Eligibility::RequirementExpression.create
    super
  end
end
