# frozen_string_literal: true

require "grape"

require "suma/api"

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
    end
    post :update do
      customer = current_customer
      set_declared(customer, params)
      save_or_error!(customer)

      status 200
      present customer, with: Suma::API::CurrentCustomerEntity, env:
    end
  end
end
