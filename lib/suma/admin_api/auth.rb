# frozen_string_literal: true

require "grape"

require "suma/admin_api"

class Suma::AdminAPI::Auth < Suma::AdminAPI::BaseV1
  include Suma::Service::Types

  resource :auth do
    desc "Return the current administrator customer."
    get do
      present admin_customer, with: Suma::AdminAPI::CurrentCustomerEntity, env:
    end

    params do
      requires :email, type: String, coerce_with: NormalizedEmail
      requires :password, type: String, allow_blank: false
    end
    post do
      guard_authed!
      me = Suma::Customer.with_email(params[:email])
      if me.nil? || !me.authenticate(params[:password])
        merror!(403, "Those credentials are invalid or that email is not in our system.", code: "invalid_credentials")
      end
      merror!(403, "This account is not an administrator.", code: "invalid_permissions") unless me.admin?
      set_customer(me)
      status 200
      present admin_customer, with: Suma::AdminAPI::CurrentCustomerEntity, env:
    end

    delete do
      delete_session_cookies
      status 204
      body ""
    end

    auth(:admin)
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
          (target = Suma::Customer[params[:customer_id]]) or forbidden!

          Suma::Service::Auth::Impersonation.new(env["warden"]).on(target)

          status 200
          present target, with: Suma::AdminAPI::CurrentCustomerEntity, env:
        end
      end
    end
  end
end
