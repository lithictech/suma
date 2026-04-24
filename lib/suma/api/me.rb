# frozen_string_literal: true

require "grape"

require "suma/api"
require "suma/member/dashboard"

class Suma::API::Me < Suma::API::V1
  include Suma::API::Entities

  helpers do
    def current_registration_link
      return Suma::Organization::RegistrationLink.from_params(cookies.send(:cookies), at: current_time)
    end
  end

  resource :me do
    desc "Return the current member"
    get do
      if (reg_linkcode = current_registration_link)
        [
          ["suma-reglink-org", reg_linkcode.link.organization.name],
          ["suma-reglink-intro", Suma::Service::Entities.render_translated_text(reg_linkcode.link.intro)],
        ].each do |(h, v)|
          header h, v
          yosoy.set_header(h, Base64.strict_encode64(v))
        end

      end

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

        if (reglink = current_registration_link)
          reglink.link.ensure_verified_membership(member, code: reglink.code)
          member.update(onboarding_verified_at: current_time)
          member.audit_activity("autoverified", action: reglink.link)
        end
      end
      status 200
      present member, with: CurrentMemberEntity, env:
    end

    get :dashboard do
      d = Suma::Member::Dashboard.new(current_member, at: current_time)
      present d, with: DashboardEntity
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

  class DashboardAlertEntity < BaseEntity
    expose :localization_key
    expose :localization_params
    expose :variant
  end

  class ProgramEntity < BaseEntity
    expose_translated :name
    expose_translated :description
    expose :image?, as: :image, with: Suma::API::Entities::ImageEntity
    expose :period_begin, &self.delegate_to(:period, :begin)
    expose :period_end, &self.delegate_to(:period_end_visible)
    expose :app_link
    expose_translated :app_link_text
  end

  class DashboardEntity < BaseEntity
    expose :cash_balance, with: Suma::API::Entities::MoneyEntity
    expose :programs, with: ProgramEntity
    expose :alerts, with: DashboardAlertEntity
  end
end
