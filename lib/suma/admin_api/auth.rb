# frozen_string_literal: true

require "grape"

require "suma/admin_api"

class Suma::AdminAPI::Auth < Suma::AdminAPI::BaseV1
  include Suma::Service::Types
  include Suma::AdminAPI::Entities

  resource :auth do
    desc "Return the current administrator member."
    get do
      present admin_member, with: CurrentMemberEntity, env:
    end

    params do
      requires :email, type: String, coerce_with: NormalizedEmail
      requires :password, type: String, allow_blank: false
    end
    post do
      guard_authed!
      me = Suma::Member.with_email(params[:email])
      if me.nil? || !me.authenticate(params[:password])
        merror!(403, "Those credentials are invalid or that email is not in our system.", code: "invalid_credentials")
      end
      merror!(403, "This account is not an administrator.", code: "invalid_permissions") unless me.admin?
      set_member(me)
      status 200
      present admin_member, with: CurrentMemberEntity, env:
    end

    delete do
      delete_session_cookies
      status 204
      body ""
    end

    auth(:admin)
    resource :impersonate do
      desc "Remove any active impersonation and return the admin member."
      delete do
        Suma::Service::Auth::Impersonation.new(env["warden"]).off(admin_member)

        status 200
        present admin_member, with: CurrentMemberEntity, env:
      end

      route_param :member_id, type: Integer do
        desc "Impersonate a member"
        post do
          (target = Suma::Member[params[:member_id]]) or forbidden!

          Suma::Service::Auth::Impersonation.new(env["warden"]).on(target)

          status 200
          present admin_member, with: CurrentMemberEntity, env:
        end
      end
    end
  end
end
