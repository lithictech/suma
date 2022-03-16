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

  before(:each) do
    Suma::Customer.reset_configuration
  end
  after(:each) do
    Suma::Customer.reset_configuration
  end

  describe "POST /v1/auth/start" do
    it "errors if a customer is already authed" do
      c = Suma::Fixtures.customer.create
      login_as(c)

      post("/v1/auth/start", phone: "(222) 333-4444", timezone:)

      expect(last_response).to have_status(409)
      expect(last_response).to have_json_body.
        that_includes(error: include(message: "You are already signed in. Please sign out first."))
    end

    describe "when the phone number does not exist" do
      it "creates a customer with the given phone number and dispatches an SMS" do
        post("/v1/auth/start", phone: "(222) 333-4444", timezone:)

        expect(last_response).to have_status(200)
        expect(last_response_json_body).to be_empty
        expect(last_response).to have_session_cookie.with_no_extra_keys
        expect(Suma::Customer.all).to contain_exactly(have_attributes(phone: "12223334444"))
        customer = Suma::Customer.first
        expect(customer.reset_codes).to contain_exactly(have_attributes(transport: "sms"))
      end

      it "creates a journey" do
        post("/v1/auth/start", phone: "(222) 333-4444", timezone:)

        expect(last_response).to have_status(200)
        expect(Suma::Customer.last.journeys).to contain_exactly(have_attributes(name: "registered"))
      end
    end

    describe "when the phone number belongs to a customer" do
      it "dispatches an SMS" do
        existing = Suma::Fixtures.customer(phone: "12223334444").create

        post("/v1/auth/start", phone: "(222) 333-4444", timezone:)

        expect(last_response).to have_status(200)
        expect(last_response_json_body).to be_empty
        expect(last_response).to have_session_cookie.with_no_extra_keys
        expect(Suma::Customer.all).to contain_exactly(be === existing)
        expect(existing.reset_codes).to contain_exactly(have_attributes(transport: "sms"))
      end

      it "does not create a journey" do
        c = Suma::Fixtures.customer(phone: full_phone).create

        post("/v1/auth/start", phone: c.phone, timezone:)

        expect(last_response).to have_status(200)
        expect(Suma::Customer::Journey.all).to be_empty
      end
    end
  end

  describe "POST /v1/auth/verify" do
    it "errors if a customer is already authed" do
      c = Suma::Fixtures.customer.create
      login_as(c)

      post("/v1/auth/verify", phone: "(222) 333-4444", token: "abc")

      expect(last_response).to have_status(409)
      expect(last_response).to have_json_body.
        that_includes(error: include(message: "You are already signed in. Please sign out first."))
    end

    it "returns 200 and creates a session if the phone number and OTP are valid" do
      c = Suma::Fixtures.customer(phone: full_phone).create
      code = Suma::Fixtures.reset_code(customer: c).sms.create

      post("/v1/auth/verify", phone: c.phone, token: code.token)

      expect(last_response).to have_status(200)
      expect(last_response).to have_session_cookie.with_payload_key("warden.user.customer.key")
      expect(last_response).to have_json_body.
        that_includes(id: c.id, phone: fmt_phone)
      expect(code.refresh).to be_expired
    end

    it "returns a 200 and creates a session if the customer exists and skip verification is configured" do
      c = Suma::Fixtures.customer.create
      Suma::Customer.skip_verification_allowlist = ["*"]

      post("/v1/auth/verify", phone: c.phone, token: "abc")

      expect(last_response).to have_status(200)
    end

    it "returns 401 if the phone number does not map to a customer" do
      code = Suma::Fixtures.reset_code.sms.create

      post("/v1/auth/verify", phone: "15551112222", token: code.token)

      expect(last_response).to have_status(401)
    end

    it "returns 401 if the OTP is not valid for the phone number" do
      code = Suma::Fixtures.reset_code.sms.create
      code.expire!

      post("/v1/auth/verify", phone: code.customer.phone, token: code.token)

      expect(last_response).to have_status(401)
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
