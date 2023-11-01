# frozen_string_literal: true

require "grape"
require "suma/admin_api"

class Suma::AdminAPI::EligibilityConstraints < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  resource :constraints do
    params do
      use :pagination
      use :ordering, model: Suma::Eligibility::Constraint
      use :searchable
    end
    get do
      ds = Suma::Eligibility::Constraint.dataset
      if (name_like = search_param_to_sql(params, :name))
        ds = ds.where(name_like)
      end
      ds = order(ds, params)
      ds = paginate(ds, params)
      present_collection ds, with: EligibilityConstraintEntity
    end

    params do
      requires :name, type: String, allow_blank: false
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

    route_param :id, type: Integer do
      helpers do
        def lookup
          (ec = Suma::Eligibility::Constraint[params[:id]]) or forbidden!
          return ec
        end
      end

      get do
        ec = lookup
        present ec, with: DetailedEligibilityConstraintEntity
      end
    end
  end

  class VendorServiceEntity < BaseEntity
    include Suma::AdminAPI::Entities
    include AutoExposeBase
    expose :external_name, as: :name
  end

  class DetailedEligibilityConstraintEntity < EligibilityConstraintEntity
    include Suma::AdminAPI::Entities
    expose :associated_offerings, as: :offerings, with: OfferingEntity
    expose :associated_vendor_services, as: :services, with: VendorServiceEntity
  end
end
