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
      optional :organization_name, type: String, allow_blank: false
    end
    post :update do
      member = current_member
      member.db.transaction do
        set_declared(member, params, ignore: [:address, :organization_name])
        save_or_error!(member)
        if params.key?(:address)
          member.legal_entity.address = Suma::Address.lookup(params[:address])
          save_or_error!(member.legal_entity)
        end
        member.ensure_membership_in_organization(params[:organization_name]) if params.key?(:organization_name)
      end
      status 200
      present member, with: CurrentMemberEntity, env:
    end

    get :dashboard do
      d = Suma::Member::Dashboard.new(current_member, at: Time.now)
      present d, with: MemberDashboardEntity
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

  class DashboardLedgerLineEntity < BaseEntity
    include Suma::API::Entities
    include LedgerLineAmountMixin
    expose :apply_at, as: :at
    expose_translated :memo
  end

  class VendibleEntity < BaseEntity
    include Suma::API::Entities
    expose_translated :name
    expose :until
    expose :image, with: ImageEntity
    expose :link
  end

  class VendibleGroupingEntity < BaseEntity
    expose_translated :name, &self.delegate_to(:group, :name)
    expose :vendibles, with: VendibleEntity
  end

  class MemberDashboardEntity < BaseEntity
    include Suma::API::Entities
    expose :vendible_groupings, with: VendibleGroupingEntity
  end
end
