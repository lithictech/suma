# frozen_string_literal: true

require "grape"

require "suma/api"
require "suma/member/dashboard"

class Suma::API::Me < Suma::API::V1
  resource :me do
    desc "Return the current member"
    get do
      member = current_member
      if member.sessions_dataset.empty?
        # Add this as a way to backfill sessions for users that last authed before we had them.
        member.add_session(**Suma::Member::Session.params_for_request(request))
      end
      present member, with: Suma::API::CurrentMemberEntity, env:
    end

    desc "Update supported fields on the member"
    params do
      optional :name, type: String, allow_blank: false
      optional :address, type: JSON do
        use :address
      end
    end
    post :update do
      member = current_member
      member.db.transaction do
        set_declared(member, params, ignore: [:address])
        save_or_error!(member)
        if params.key?(:address)
          member.legal_entity.address = Suma::Address.lookup(params[:address])
          save_or_error!(member.legal_entity)
        end
      end
      status 200
      present member, with: Suma::API::CurrentMemberEntity, env:
    end

    get :dashboard do
      d = Suma::Member::Dashboard.new(current_member)
      present d, with: Suma::API::MemberDashboardEntity
    end
  end
end
