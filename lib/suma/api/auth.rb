# frozen_string_literal: true

require "grape"
require "name_of_person"
require "suma/api"
require "rack/auth_rate_limit"

class Suma::API::Auth < Suma::API::V1
  include Suma::Service::Types
  include Suma::API::Entities
  use Rack::AuthRateLimit

  ALL_TIMEZONES = Set.new(TZInfo::Timezone.all_identifiers)

  helpers do
    def create_session(member)
      member.add_session(**Suma::Member::Session.params_for_request(request))
    end
  end

  resource :auth do
    desc "Start the authentication process"
    params do
      requires :phone, us_phone: true, type: String, coerce_with: NormalizedPhone
      requires :timezone, type: String, values: ALL_TIMEZONES
      optional :language, type: String, values: Suma::I18n.enabled_locale_codes
      optional :terms_agreed, type: Boolean
    end
    post :start do
      guard_authed!
      Suma::Member.db.transaction do
        member = Suma::Member.with_us_phone(params[:phone])
        is_new = member.nil?
        member ||= Suma::Member.new(
          phone: params[:phone],
          name: "",
          password_digest: Suma::Member::PLACEHOLDER_PASSWORD_DIGEST,
          terms_agreed: params[:terms_agreed] ? Suma::Member::LATEST_TERMS_PUBLISH_DATE : nil,
        )
        member.timezone = params[:timezone]
        save_or_error!(member)
        if is_new
          member.add_activity(
            message_name: "registered",
            summary: "Created from API",
            subject_type: "Suma::Member",
            subject_id: member.id,
          )
        end
        Suma::Member::ResetCode.replace_active(member, transport: "sms")
        member.message_preferences!.update(preferred_language: params[:language]) if params[:language].present?
        status 200
        present member, with: AuthFlowMemberEntity
      end
    end

    params do
      requires :phone, us_phone: true, type: String, coerce_with: NormalizedPhone
      requires :token, type: String, allow_blank: false
    end
    post :verify do
      guard_authed!
      me = Suma::Member.with_us_phone(params[:phone])
      begin
        Suma::Member::ResetCode::Unusable if me.nil?
        if Suma::Member.matches_allowlist?(me, Suma::Member.superadmin_allowlist)
          me.update(onboarding_verified_at: Time.now) unless me.onboarding_verified?
          me.ensure_role(Suma::Role.admin_role)
        elsif Suma::Member.matches_allowlist?(me, Suma::Member.onboard_allowlist)
          me.update(onboarding_verified_at: Time.now) unless me.onboarding_verified?
        elsif Suma::Member.matches_allowlist?(me, Suma::Member.skip_verification_allowlist)
          nil
        else
          Suma::Member::ResetCode.use_code_with_token(params[:token]) do |code|
            raise Suma::Member::ResetCode::Unusable unless code.member === me
          end
        end
      rescue Suma::Member::ResetCode::Unusable
        merror!(403, "Sorry, that token is invalid or the phone number is not in our system.", code: "invalid_otp")
      end

      session = create_session(me)
      set_session(session)
      status 200
      present me, with: CurrentMemberEntity, env:
    end

    delete do
      logout
      status 204
      body ""
    end

    desc "Add member to contact list referral"
    params do
      requires :name, type: String, allow_blank: false
      requires :phone, us_phone: true, type: String, coerce_with: NormalizedPhone
      requires :channel, type: String, allow_blank: false
      requires :timezone, type: String, values: ALL_TIMEZONES
      optional :event_name, type: String
      optional :language, type: String, values: Suma::I18n.enabled_locale_codes
      optional :organization_name, type: String
    end
    post :contact_list do
      guard_authed!
      Suma::Member.db.transaction do
        member = Suma::Member.with_us_phone(params[:phone])
        if member.nil?
          member = Suma::Member.new(
            phone: params[:phone],
            name: params[:name],
            password_digest: Suma::Member::PLACEHOLDER_PASSWORD_DIGEST,
            timezone: params[:timezone],
          )
          save_or_error!(member)
          Suma::Member::Referral.create(
            member:,
            channel: params[:channel],
            event_name: params[:event_name] || "",
          )
          member.add_activity(
            message_name: "registered",
            summary: "Created from referral API",
            subject_type: "Suma::Member",
            subject_id: member.id,
          )
          member.message_preferences!.update(preferred_language: params[:language]) if params[:language].present?
        else
          member.add_activity(
            message_name: "added_to_contact_list",
            summary: "Added to contact list (channel: #{params[:channel]}, event_name: #{params[:event_name] || ''})",
            subject_type: "Suma::Member",
            subject_id: member.id,
          )
        end
        member.ensure_membership_in_organization(params[:organization_name]) if params.key?(:organization_name)
        status 200
      end
    end
  end

  class AuthFlowMemberEntity < BaseEntity
    expose :requires_terms_agreement?, as: :requires_terms_agreement
  end
end
