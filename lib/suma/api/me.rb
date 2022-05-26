# frozen_string_literal: true

require "grape"

require "suma/api"
require "suma/customer/dashboard"

class Suma::API::Me < Suma::API::V1
  resource :me do
    desc "Return the current customer"
    get do
      customer = current_customer
      if customer.sessions_dataset.empty?
        # Add this as a way to backfill sessions for users that last authed before we had them.
        customer.add_session(**Suma::Customer::Session.params_for_request(request))
      end
      present customer, with: Suma::API::CurrentCustomerEntity, env:
    end

    desc "Update supported fields on the customer"
    params do
      optional :name, type: String, allow_blank: false
      optional :address, type: JSON do
        use :address
      end
    end
    post :update do
      customer = current_customer
      customer.db.transaction do
        set_declared(customer, params, ignore: [:address])
        save_or_error!(customer)
        if params.key?(:address)
          customer.legal_entity.address = Suma::Address.lookup(params[:address])
          save_or_error!(customer.legal_entity)
        end
      end
      status 200
      present customer, with: Suma::API::CurrentCustomerEntity, env:
    end

    get :dashboard do
      d = Suma::Customer::Dashboard.new(current_customer)
      present d, with: Suma::API::CustomerDashboardEntity
    end
  end
end
