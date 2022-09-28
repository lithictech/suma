# frozen_string_literal: true

require "grape"
require "name_of_person"
require "suma/api"

class Suma::API::Auth < Suma::API::V1
  include Suma::Service::Types

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
        member.add_reset_code({transport: "sms"})
        status 200
        present member, with: Suma::API::AuthFlowMemberEntity
      end
    end

    params do
      requires :phone, us_phone: true, type: String, coerce_with: NormalizedPhone
      requires :token, type: String, allow_blank: false
      optional :terms_agreed, type: Boolean
    end
    post :verify do
      guard_authed!
      me = Suma::Member.with_us_phone(params[:phone])
      begin
        Suma::Member::ResetCode::Unusable if me.nil?
        if Suma::Member.matches_allowlist?(me, Suma::Member.superadmin_allowlist)
          me.update(onboarding_verified_at: Time.now)
          me.ensure_role(Suma::Role.admin_role)
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

      me.update(terms_agreed: Suma::Member::LATEST_TERMS_PUBLISH_DATE) if params[:terms_agreed]
      set_member(me)
      create_session(me)
      status 200
      present me, with: Suma::API::CurrentMemberEntity, env:
    end

    delete do
      delete_session_cookies
      status 204
      body ""
    end
  end
end
