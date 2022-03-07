# frozen_string_literal: true

require "grape"

require "suma/admin_api"

class Suma::AdminAPI::Auth < Suma::AdminAPI::V1
  resource :auth do
    desc "Return the current administrator customer."
    get do
      present admin_customer, with: Suma::AdminAPI::CurrentCustomerEntity, env:
    end

    resource :impersonate do
      desc "Remove any active impersonation and return the admin customer."
      delete do
        Suma::Service::Auth::Impersonation.new(env["warden"]).off(admin_customer)

        status 200
        present admin_customer, with: Suma::AdminAPI::CurrentCustomerEntity, env:
      end

      route_param :customer_id, type: Integer do
        desc "Impersonate a customer"
        post do
          (target = Suma::Customer[params[:customer_id]]) or not_found!

          Suma::Service::Auth::Impersonation.new(env["warden"]).on(target)

          status 200
          present target, with: Suma::AdminAPI::CurrentCustomerEntity, env:
        end
      end
    end
  end
end
