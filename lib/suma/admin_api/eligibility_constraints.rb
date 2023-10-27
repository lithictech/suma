# frozen_string_literal: true

require "grape"
require "suma/admin_api"

class Suma::AdminAPI::EligibilityConstraints < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  resource :constraints do
    params do
      requires :name, type: String
    end
    post :create do
      Suma::Eligibility::Constraint.db.transaction do
        constraint = Suma::Eligibility::Constraint[name: params[:name]]
        adminerror!(403, "Eligibility constraint #{constraint.name} already exists") unless
          constraint.nil?
        ec = Suma::Eligibility::Constraint.create(name: params[:name])

        created_resource_headers(ec.id, ec.admin_link)
        status 200
        present ec, with: EligibilityConstraintEntity
      end
    end
  end
end
