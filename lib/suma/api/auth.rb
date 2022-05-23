# frozen_string_literal: true

require "grape"
require "name_of_person"
require "suma/api"

class Suma::API::Auth < Suma::API::V1
  include Suma::Service::Types

  ALL_TIMEZONES = Set.new(TZInfo::Timezone.all_identifiers)

  helpers do
    def create_session(customer)
      customer.add_session(**Suma::Customer::Session.params_for_request(request))
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
      Suma::Customer.db.transaction do
        customer = Suma::Customer.with_us_phone(params[:phone])
        is_new = customer.nil?
        customer ||= Suma::Customer.new(
          phone: params[:phone],
          name: "",
          password_digest: Suma::Customer::PLACEHOLDER_PASSWORD_DIGEST,
        )
        customer.timezone = params[:timezone]
        save_or_error!(customer)
        if is_new
          customer.add_journey(
            name: "registered",
            message: "Created from API",
            subject_type: "Suma::Customer",
            subject_id: customer.id,
          )
        end
        customer.add_reset_code({transport: "sms"})
        status 200
        present({})
      end
    end

    params do
      requires :phone, us_phone: true, type: String, coerce_with: NormalizedPhone
      requires :token, type: String, allow_blank: false
    end
    post :verify do
      guard_authed!
      me = Suma::Customer.with_us_phone(params[:phone])
      begin
        Suma::Customer::ResetCode::Unusable if me.nil?
        if Suma::Customer.skip_verification?(me)
          me.update(onboarding_verified_at: Time.now)
        else
          Suma::Customer::ResetCode.use_code_with_token(params[:token]) do |code|
            raise Suma::Customer::ResetCode::Unusable unless code.customer === me
          end
        end
      rescue Suma::Customer::ResetCode::Unusable
        merror!(403, "Sorry, that token is invalid or the phone number is not in our system.", code: "invalid_otp")
      end

      set_customer(me)
      create_session(me)
      status 200
      present me, with: Suma::API::CurrentCustomerEntity, env:
    end

    delete do
      delete_session_cookies
      status 204
      body ""
    end
  end
end
