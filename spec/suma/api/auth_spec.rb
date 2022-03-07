# frozen_string_literal: true

require "suma/api/auth"

RSpec.describe Suma::API::Auth, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }

  let(:email) { "jane@farmers.org" }
  let(:other_email) { "diff-" + email }
  let(:password) { "1234abcd!" }
  let(:other_password) { password + "abc" }
  let(:name) { "David Graeber" }
  let(:phone) { "1234567890" }
  let(:full_phone) { "11234567890" }
  let(:other_phone) { "1234567999" }
  let(:other_full_phone) { "11234567999" }
  let(:fmt_phone) { "(123) 456-7890" }
  let(:timezone) { "America/Juneau" }
  let(:customer_params) do
    {name:, email:, phone:, password:, timezone:}
  end
  let(:customer_create_params) { customer_params.merge(phone: full_phone) }

  describe "POST /v1/register" do
    it "creates an unverified customer with the given parameters" do
      post "/v1/register", **customer_params

      expect(last_response).to have_status(200)

      customer = Suma::Customer.last
      expect(customer).to_not be_nil
      expect(customer).to have_attributes(
        name:,
        us_phone: fmt_phone,
        email:,
        timezone: "America/Juneau",
        phone_verified?: false,
        email_verified?: false,
      )
      expect(customer.authenticate(password)).to be_truthy
      expect(customer.reset_codes).to contain_exactly(have_attributes(transport: "sms"))
    end

    it "verifies the customer if skip_verification is set" do
      Suma::Customer.skip_phone_verification = true
      Suma::Customer.skip_email_verification = true

      post "/v1/register", **customer_params

      expect(last_response).to have_status(200)
      customer = Suma::Customer.last
      expect(customer).to have_attributes(
        phone_verified?: true,
        email_verified?: true,
      )
      expect(customer.reset_codes).to be_empty
    ensure
      Suma::Customer.reset_configuration
    end

    it "returns the customer in the body and a session in a cookie" do
      post "/v1/register", customer_params

      expect(last_response).to have_status(200)
      expect(last_response).to have_session_cookie
      expect(last_response).to have_json_body.
        that_includes(
          :id,
          name:,
          email:,
          phone: fmt_phone,
          email_verified: false,
          phone_verified: false,
        )
    end

    it "will use a default password" do
      customer_params.delete(:password)

      post "/v1/register", **customer_params

      expect(last_response).to have_status(200)
      expect(Suma::Customer.last).to have_attributes(password_digest: Suma::Customer::PLACEHOLDER_PASSWORD_DIGEST)
    end

    it "replaces the auth of an already-logged-in customer" do
      customer = Suma::Fixtures.customer.create
      login_as(customer)

      post "/v1/register", customer_params

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: be > customer.id, name:)
    end

    it "creates a journey for a new customer" do
      post "/v1/register", **customer_params

      expect(last_response).to have_status(200)

      expect(Suma::Customer.last.journeys).to contain_exactly(have_attributes(name: "registered"))
    end

    it "does not create a journey for an existing customer" do
      c = Suma::Fixtures.customer(**customer_create_params).create

      post "/v1/register", **customer_params

      expect(last_response).to have_status(200)

      expect(Suma::Customer::Journey.all).to be_empty
    end

    it "requires a valid phone" do
      post "/v1/register", customer_params.merge(phone: "123456129abc")

      expect(last_response).to have_status(400)
      expect(last_response).to have_json_body.
        that_includes(error: include(message: "Phone must be a 10-digit US phone"))

      post "/v1/register", customer_params.merge(phone: "234")

      expect(last_response).to have_status(400)
      expect(last_response).to have_json_body.
        that_includes(error: include(message: "Phone must be a 10-digit US phone"))
    end

    it "lowercases the email" do
      post "/v1/register", customer_params.merge(email: "HEARME@ROAR.coM")

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(email: "hearme@roar.com")
      expect(Suma::Customer.last).to have_attributes(email: "hearme@roar.com")
    end

    it "trims spaces from name and email" do
      post "/v1/register", customer_params.merge(name: " Space  Balls ", email: " barf@sb.com ")

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(name: "Space Balls", email: "barf@sb.com")
      expect(Suma::Customer.last).to have_attributes(name: "Space Balls", email: "barf@sb.com")
    end

    it "formats the phone number" do
      post "/v1/register", customer_params.merge(phone: "  123- 456 8909 ")

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(phone: "(123) 456-8909")
      expect(Suma::Customer.last).to have_attributes(phone: "11234568909")
    end

    it "creates a session" do
      post "/v1/register", customer_params

      expect(last_response).to have_status(200)
      cust = Suma::Customer.last
      expect(Suma::Customer::Session.last).to have_attributes(customer: be === cust)
    end

    describe "conflict specification (see docs)" do
      describe "email and phone match existing, different users" do
        it "errors that email and phone are in use" do
          Suma::Fixtures.customer.create(customer_create_params.merge(phone: other_full_phone))
          Suma::Fixtures.customer.create(customer_create_params.merge(email: other_email))
          post "/v1/register", **customer_params
          expect(last_response).to have_status(400)
          expect(last_response).to have_json_body.
            that_includes(error: include(message: "Sorry, this email and phone number is already in use."))
        end
      end
      describe "email and phone match the same user" do
        it "if both unverified, update password and log in" do
          c = Suma::Fixtures.customer.unverified.create(customer_create_params.merge(password: other_password))
          post "/v1/register", **customer_params
          expect(last_response).to have_status(200)
          expect(c.refresh.authenticate(password)).to be_truthy
        end
        it "if phone and/or email are verified and passwords match, log in" do
          Suma::Fixtures.customer.create(customer_create_params.merge(phone_verified_at: nil))
          post "/v1/register", **customer_params
          expect(last_response).to have_status(200)
        end
        it "else, error that user already has an account" do
          Suma::Fixtures.customer.create(customer_create_params.merge(password: other_password))
          post "/v1/register", **customer_params
          expect(last_response).to have_status(400)
          expect(last_response).to have_json_body.
            that_includes(error: include(message: "Sorry, this email and phone number is already in use."))
        end
      end
      describe "phone matches an existing user, email does not" do
        let!(:c) { Suma::Fixtures.customer.create(customer_create_params.merge(email: other_email)) }
        it "if phone and email are unverified, replace email and password and log in" do
          c.update(phone_verified_at: nil, email_verified_at: nil, password: other_password)
          post "/v1/register", **customer_params
          expect(last_response).to have_status(200)
          expect(c.refresh.email).to eq(email)
          expect(c.authenticate(password)).to be_truthy
        end
        it "if phone is unverified and email is verified, and password matches, error that email is already used" do
          c.update(phone_verified_at: nil)
          post "/v1/register", **customer_params
          expect(last_response).to have_status(400)
          expect(last_response).to have_json_body.
            that_includes(error: include(message: "Sorry, this email is already in use."))
        end
        it "if phone is verified and email is unverified, and password matches, replace email and log in" do
          c.update(email_verified_at: nil)
          post "/v1/register", **customer_params
          expect(last_response).to have_status(200)
          expect(c.refresh.email).to eq(email)
        end
        it "if phone and email are verified, and password matches, error that phone is already used" do
          post "/v1/register", **customer_params
          expect(last_response).to have_status(400)
          expect(last_response).to have_json_body.
            that_includes(error: include(message: "Sorry, this phone number is already in use with a different email."))
        end
        it "else, error that an account already exists" do
          # Dupe of above test
          c.update(password: other_password)
          post "/v1/register", **customer_params
          expect(last_response).to have_status(400)
          expect(last_response).to have_json_body.
            that_includes(error: include(message: "Sorry, this phone number is already in use with a different email."))
        end
      end
      describe "email matches an existing user, phone does not" do
        let!(:c) { Suma::Fixtures.customer.create(customer_create_params.merge(phone: other_full_phone)) }
        it "if email and phone are unverified, replace phone and password and log in" do
          c.update(phone_verified_at: nil, email_verified_at: nil, password: other_password)
          post "/v1/register", **customer_params
          expect(last_response).to have_status(200)
          expect(c.refresh.phone).to eq(full_phone)
          expect(c.authenticate(password)).to be_truthy
        end
        it "if email is unverified and phone is verified, and password matches, error that phone is already used" do
          c.update(email_verified_at: nil)
          post "/v1/register", **customer_params
          expect(last_response).to have_status(400)
          expect(last_response).to have_json_body.
            that_includes(error: include(message: "Sorry, this phone number is already in use."))
        end
        it "if email is verified and phone is unverified, and password matches, replace phone and log in" do
          c.update(phone_verified_at: nil)
          post "/v1/register", **customer_params
          expect(last_response).to have_status(200)
          expect(c.refresh.phone).to eq(full_phone)
        end
        it "if email and phone are verified, and password matches, error that email is already used" do
          post "/v1/register", **customer_params
          expect(last_response).to have_status(400)
          expect(last_response).to have_json_body.
            that_includes(error: include(message: "Sorry, this email is already in use with a different phone number."))
        end
        it "else, error that an account already exists" do
          # Dupe of above test
          c.update(password: other_password)
          post "/v1/register", **customer_params
          expect(last_response).to have_status(400)
          expect(last_response).to have_json_body.
            that_includes(error: include(message: "Sorry, this email is already in use with a different phone number."))
        end
      end
    end
  end

  describe "POST /v1/auth" do
    let!(:customer) { Suma::Fixtures.customer(**customer_create_params).create }

    it "returns 200 with the customer data and a session cookie if phone is verified and password matches" do
      post "/v1/auth", phone: phone, password: password

      expect(last_response).to have_status(200)
      expect(last_response).to have_session_cookie
      expect(last_response).to have_json_body.
        that_includes(name:, phone: fmt_phone)
    end

    it "returns 401 if the password does not match" do
      post "/v1/auth", phone: phone, password: "a" + password

      expect(last_response).to have_status(401)
      expect(last_response.body).to include("Incorrect password")
    end

    it "returns 401 if the phone has no customer" do
      post "/v1/auth", phone: "111-111-1111", password: password

      expect(last_response).to have_status(401)
      expect(last_response.body).to include("No customer with that phone")
    end

    it "succeeds if email is verified and password matches" do
      post "/v1/auth", email: email, password: password

      expect(last_response).to have_status(200)
      expect(last_response).to have_session_cookie
      expect(last_response).to have_json_body.that_includes(id: customer.id)
    end

    it "returns 401 if email has no customer" do
      post "/v1/auth", email: "a@b.c", password: password

      expect(last_response).to have_status(401)
      expect(last_response.body).to include("No customer with that email")
    end

    it "replaces the auth of an already-logged-in customer" do
      other_cust = Suma::Fixtures.customer.create
      login_as(other_cust)

      post "/v1/auth", phone: phone, password: password

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: customer.id)
    end

    it "creates a session" do
      post "/v1/auth", phone: phone, password: password

      expect(last_response).to have_status(200)
      cust = Suma::Customer.last
      expect(Suma::Customer::Session.last).to have_attributes(customer: be === cust)
    end
  end

  describe "POST /v1/auth/verify" do
    let(:customer) { Suma::Fixtures.customer(**customer_create_params).unverified.create }

    before(:each) do
      login_as(customer)
    end

    it "tries to verify the customer" do
      code = customer.add_reset_code(transport: "sms")
      expect(customer).to_not be_phone_verified
      expect(customer).to_not be_email_verified

      post "/v1/auth/verify", token: code.token

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(phone_verified: true)
      customer.refresh
      expect(customer).to be_phone_verified
      expect(customer).to_not be_email_verified
    end

    it "tries to verify the customer email" do
      code = customer.add_reset_code(transport: "email")
      expect(customer).to_not be_email_verified
      expect(customer).to_not be_phone_verified

      post "/v1/auth/verify", token: code.token

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(email_verified: true)
      customer.refresh
      expect(customer).to be_email_verified
      expect(customer).to_not be_phone_verified
    end

    it "400s if the token does not belong to the current customer" do
      code = Suma::Fixtures.reset_code.create

      post "/v1/auth/verify", token: code.token

      expect(last_response).to have_status(400)
      expect(last_response).to have_json_body.
        that_includes(error: include(message: "Invalid verification code"))
    end

    it "400s if the token is invalid" do
      code = Suma::Fixtures.reset_code(customer:).create
      code.expire!

      post "/v1/auth/verify", token: code.token

      expect(last_response).to have_status(400)
      expect(last_response).to have_json_body.
        that_includes(error: include(message: "Invalid verification code"))
    end
  end

  describe "POST /v1/auth/resend_verification" do
    let(:customer) { Suma::Fixtures.customer(**customer_create_params).create }
    let!(:sms_code) { Suma::Fixtures.reset_code(customer:).sms.create }
    let!(:email_code) { Suma::Fixtures.reset_code(customer:).email.create }

    before(:each) do
      login_as(customer)
    end

    it "expires and creates a new sms reset code for the customer" do
      post "/v1/auth/resend_verification", transport: "sms"

      expect(last_response).to have_status(204)
      expect(sms_code.refresh).to be_expired
      expect(email_code.refresh).to_not be_expired
      new_code = customer.refresh.reset_codes.first
      expect(new_code).to_not be_expired
      expect(new_code).to have_attributes(transport: "sms")
    end

    it "expires and creates a new email reset code for the customer" do
      post "/v1/auth/resend_verification", transport: "email"

      expect(last_response).to have_status(204)
      expect(sms_code.refresh).to_not be_expired
      expect(email_code.refresh).to be_expired
      new_code = customer.refresh.reset_codes.first
      expect(new_code).to_not be_expired
      expect(new_code).to have_attributes(transport: "email")
    end
  end

  describe "DELETE /v1/auth" do
    it "removes the cookies" do
      delete "/v1/auth"

      expect(last_response).to have_status(204)
      expect(last_response["Set-Cookie"]).to include("=deleted; path=/; expires=Thu, 01 Jan 1970 00:00:00")
    end
  end
end
