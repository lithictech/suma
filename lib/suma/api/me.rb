# frozen_string_literal: true

require "grape"

require "suma/api"
require "suma/member/dashboard"

class Suma::API::Me < Suma::API::V1
  include Suma::API::Entities

  resource :me do
    desc "Return the current member"
    get do
      member = current_member
      if member.sessions_dataset.empty?
        # Add this as a way to backfill sessions for users that last authed before we had them.
        member.add_session(**Suma::Member::Session.params_for_request(request))
      end
      # Expect JS to store this response, rather than the browser.
      # If the browser stores it, we can end up requesting stale auth info
      # out of the local cache even once we're signed out.
      header "Cache-Control", "no-store"
      present member, with: CurrentMemberEntity, env:
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
      present member, with: CurrentMemberEntity, env:
    end

    get :dashboard do
      d = Suma::Member::Dashboard.new(current_member)
      present d, with: MemberDashboardEntity
    end

    params do
      requires :feature, type: String, values: ["food", "utilities", "mobility"]
    end
    post :waitlist do
      member = current_member
      member.db[:member_key_values].
        insert_conflict.
        insert(member_id: member.id, key: "waitlist_#{params[:feature]}")
      status 200
      present member, with: CurrentMemberEntity, env:
    end

    params do
      requires :language, values: ["en", "es"]
    end
    post :language do
      member = current_member
      member.db.transaction do
        member.message_preferences!.update(preferred_language: params[:language])
      end
      status 200
      present member, with: CurrentMemberEntity, env:
    end
  end

  # class SimpleMemberOfferingsEntity < BaseEntity
  #   include Suma::API::Entities
  #   # expose :id
  #   expose_translated :description
  # end

  class MemberDashboardEntity < BaseEntity
    include Suma::API::Entities
    expose :payment_account_balance, with: MoneyEntity
    expose :lifetime_savings, with: MoneyEntity
    expose :ledger_lines, with: LedgerLineEntity
    expose :available_offerings, &self.delegate_to(:available_offerings)
  end
end
