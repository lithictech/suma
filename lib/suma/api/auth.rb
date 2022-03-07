# frozen_string_literal: true

require "grape"
require "name_of_person"
require "suma/api"

class Suma::API::Auth < Suma::API::V1
  ALL_TIMEZONES = Set.new(TZInfo::Timezone.all_identifiers)

  helpers do
    def create_session(customer)
      customer.add_session(**Suma::Customer::Session.params_for_request(request))
    end
  end

  resource :register do
    helpers do
      # Registration is a beast, since phone and email are both unique.
      # There are a whole bunch of situations customers can be in.
      # PLEASE keep the code and specs up to date with this matrix.
      #
      # - Phone nor email match an existing user:
      #   - do registration
      # - Email and phone match existing, different users:
      #   - error that email and phone are in use
      # - Email and phone match the same user:
      #   - if both unverified, update password and log in
      #   - if phone and/or email are verified and passwords match, log in
      #   - else, error that user already has an account
      # - Phone matches an existing user, email does not:
      #   - if phone and email are unverified, replace email and password and log in
      #   - if phone is unverified and email is verified, and password matches, error that email is already used
      #   - if phone is verified and email is unverified, and password matches, replace email and log in
      #   - if phone and email are verified, and password matches, error that phone is already used
      #   - else, error that an account already exists
      # - Same as previous, but reverse phone/email.
      #
      # Password
      #
      # Passwords are optional. If, on registration, there is no password, use the empty placeholder.
      # This will allow the customer to change it later.
      def check_existing_customer!(email, phone, password)
        with_email = Suma::Customer.with_email(email)
        with_phone = Suma::Customer.with_us_phone(phone)
        return nil if with_email.nil? && with_phone.nil?

        invalid!(["email or phone in use"], message: "Sorry, this email and phone number is already in use.") if
          with_email && with_phone && !(with_email === with_phone)

        password_match = (with_email || with_phone).authenticate(password)

        if with_email && with_phone && with_email === with_phone
          return with_email if with_email.unverified?
          return with_email if password_match
          invalid!(["email or phone in use"], message: "Sorry, this email and phone number is already in use.")
        end

        if with_phone && with_email.nil?
          return with_phone if with_phone.unverified?
          invalid!(["email in use"], message: "Sorry, this email is already in use.") if
            !with_phone.phone_verified? && with_phone.email_verified? && password_match
          return with_phone if with_phone.phone_verified? && !with_phone.email_verified? && password_match
          invalid!(["phone in use"], message: "Sorry, this phone number is already in use with a different email.")
        end

        raise "Unexpected condition, should have had email user and no phone" unless with_phone.nil? && with_email
        return with_email if with_email.unverified?
        invalid!(["phone in use"], message: "Sorry, this phone number is already in use.") if
          !with_email.email_verified? && with_email.phone_verified? && password_match
        return with_email if with_email.email_verified? && !with_email.phone_verified? && password_match
        invalid!(["email in use"], message: "Sorry, this email is already in use with a different phone number.")
      end
    end
    desc "Create a new customer"
    params do
      requires :email, type: String, allow_blank: false
      requires :phone, us_phone: true, allow_blank: false
      requires :timezone, type: String, values: ALL_TIMEZONES
      optional :password, type: String, allow_blank: false
      optional :name, type: String, allow_blank: false, default: ""
    end
    post do
      if (c = current_customer?)
        self.logger.warn "conflicting_login",
                         registering_phone: params[:phone],
                         existing_phone: c.phone,
                         existing_user_id: c.id
      end

      phone = Suma::PhoneNumber::US.normalize(params[:phone])
      email = params[:email].strip.downcase
      password = params.delete(:password)

      customer_params = {
        email:,
        phone:,
        timezone: params[:timezone],
        password:,
        name: params[:name].strip.squish,
      }

      Suma::Customer.db.transaction do
        customer = check_existing_customer!(email, phone, password)
        if (is_new = customer.nil?)
          customer_params[:password_digest] = Suma::Customer::PLACEHOLDER_PASSWORD_DIGEST if password.blank?
          customer = Suma::Customer.new(**customer_params)
        else
          customer.set(customer_params)
        end
        Suma::Customer.handle_verification_skipping(customer)
        save_or_error!(customer)
        if is_new
          customer.add_journey(
            name: "registered",
            message: "Created from API",
            subject_type: "Suma::Customer",
            subject_id: customer.id,
          )
        end
        # Email may not be verified, but we don't want to send them an email about verification yet.
        # We can do that later.
        # customer.add_reset_code({transport: "email"}) unless customer.email_verified?
        customer.add_reset_code({transport: "sms"}) unless customer.phone_verified?
        set_customer(customer)
        create_session(customer)
        status 200
        present customer, with: Suma::API::CurrentCustomerEntity, env:
      end
    end
  end

  resource :auth do
    desc "Log in using phone and password"
    params do
      optional :phone, us_phone: true, allow_blank: false
      optional :email, allow_blank: false
      exactly_one_of :phone, :email
      requires :password, type: String, allow_blank: false
    end
    post do
      if current_customer?
        env["warden"].logout
        env["warden"].clear_strategies_cache!
      end
      customer = authenticate!
      create_session(customer)
      status 200
      present customer, with: Suma::API::CurrentCustomerEntity, env:
    end

    desc "Verify the current customer phone number using the given token"
    params do
      requires :token
    end
    post :verify do
      me = current_customer
      begin
        Suma::Customer::ResetCode.use_code_with_token(params[:token]) do |code|
          invalid!("Invalid verification code") unless code.customer === me
          code.verify
          code.customer.save_changes
          me.refresh
        end
      rescue Suma::Customer::ResetCode::Unusable
        invalid!("Invalid verification code")
      end

      status 200
      present me, with: Suma::API::CurrentCustomerEntity, env:
    end

    params do
      requires :transport, values: ["sms", "email"]
    end
    post :resend_verification do
      me = current_customer
      me.db.transaction do
        me.reset_codes_dataset.where(transport: params[:transport]).usable.each(&:expire!)
        me.add_reset_code(transport: params[:transport])
      end
      body ""
      status 204
    end

    delete do
      delete_session_cookies
      status 204
      body ""
    end
  end
end
