# frozen_string_literal: true

require "suma/api/me"

RSpec.describe Suma::API::Me, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:customer) { Suma::Fixtures.customer.create }

  before(:each) do
    login_as(customer)
  end

  describe "GET /v1/me" do
    it "returns the authed customer" do
      get "/v1/me"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(email: customer.email, ongoing_trip: nil)
    end

    it "errors if the customer is soft deleted" do
      customer.soft_delete

      get "/v1/me"

      expect(last_response).to have_status(401)
    end

    it "401s if not logged in" do
      logout

      get "/v1/me"

      expect(last_response).to have_status(401)
    end

    it "adds a session if the user does not have one" do
      get "/v1/me"
      expect(last_response).to have_status(200)
      expect(Suma::Customer::Session.all).to have_length(1)
      expect(Suma::Customer::Session.last).to have_attributes(customer: be === customer)

      get "/v1/me"
      expect(last_response).to have_status(200)
      expect(Suma::Customer::Session.all).to have_length(1)
    end

    it "returns the customer's ongoing trip if they have one" do
      trip = Suma::Fixtures.mobility_trip.ongoing.create(customer:)

      get "/v1/me"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(ongoing_trip: include(id: trip.id))
    end
  end

  describe "POST /v1/me/update" do
    it "updates the given fields on the customer" do
      post "/v1/me/update", name: "Hassan", other_thing: "abcd"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(name: "Hassan")

      expect(customer.refresh).to have_attributes(name: "Hassan")
    end
  end

  describe "POST /v1/me/password" do
    let(:current_pass) { "1234abcd!" }
    let(:new_pass) { "fresh foods" }

    before(:each) do
      customer.update(password: current_pass)
    end

    it "changes the customer password" do
      post "/v1/me/password", current_password: current_pass, new_password: new_pass

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(name: customer.name)
      expect(customer.refresh.authenticate(new_pass)).to be_truthy
    end

    it "400s if the current password is invalid" do
      post "/v1/me/password", current_password: new_pass, new_password: current_pass

      expect(last_response).to have_status(400)
    end

    it "allows changing password if the current password is the placeholder" do
      customer.update(password_digest: Suma::Customer::PLACEHOLDER_PASSWORD_DIGEST)

      post "/v1/me/password", current_password: "x", new_password: new_pass

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(name: customer.name)
      expect(customer.refresh.authenticate(new_pass)).to be_truthy
    end

    it "expires usable reset codes" do
      code = Suma::Fixtures.reset_code(customer:).create

      post "/v1/me/password", current_password: current_pass, new_password: new_pass

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(name: customer.name)
      expect(code.refresh).to_not be_usable
    end
  end

  describe "POST /v1/me/forgot_password" do
    before(:each) do
      logout
    end

    it "creates a reset code for the customer with the phone" do
      customer.update(phone: "12223334444")

      post "/v1/me/forgot_password", phone: "222-333-4444"

      expect(last_response).to have_status(202)
      expect(last_response).to have_json_body.
        that_includes(phone: "(222) 333-4444")

      expect(customer.reset_codes).to contain_exactly(have_attributes(transport: "sms"))
    end

    it "creates a reset code for the customer with the email" do
      customer.update(email: "yo@abc.com")

      post "/v1/me/forgot_password", email: "yo@abc.com"

      expect(last_response).to have_status(202)
      expect(last_response).to have_json_body.
        that_includes(email: "yo@abc.com")

      expect(customer.reset_codes).to contain_exactly(have_attributes(transport: "email"))
    end

    it "403s if a customer is logged in" do
      login_as(customer)

      post "/v1/me/forgot_password", phone: customer.us_phone

      expect(last_response).to have_status(403)
      expect(last_response.body).to include("logged in")
    end

    it "403s if no customer exists with that phone" do
      post "/v1/me/forgot_password", phone: "111 111 1111"

      expect(last_response).to have_status(403)
      expect(last_response.body).to include("with that phone")
    end

    it "403s if no customer exists with that email" do
      post "/v1/me/forgot_password", email: "a@b.c"

      expect(last_response).to have_status(403)
      expect(last_response.body).to include("with that email")
    end
  end

  describe "POST /v1/me/reset_password_check" do
    let(:code) { Suma::Fixtures.reset_code(customer:).create }

    before(:each) do
      logout
    end

    it "returns valid if the token is usable" do
      post "/v1/me/reset_password_check", token: code.token

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(valid: true)
    end

    it "returns invalid if the token is not usable" do
      post "/v1/me/reset_password_check", token: "1456"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(valid: false)
    end
  end

  describe "POST /v1/me/reset_password" do
    let(:code) { Suma::Fixtures.reset_code(customer:).create }

    before(:each) do
      logout
    end

    it "resets the password for the customer with the given code" do
      post "/v1/me/reset_password", token: code.token, password: "new-password"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(id: customer.id)

      expect(customer.refresh.authenticate("new-password")).to be_truthy
      expect(code.refresh).to be_used
    end

    it "403s if the reset code does not exist" do
      code.destroy

      post "/v1/me/reset_password", token: code.token, password: "new-password"
      expect(last_response).to have_status(403)
    end

    it "403s if the reset code is unusable" do
      code.expire!

      post "/v1/me/reset_password", token: code.token, password: "new-password"
      expect(last_response).to have_status(403)
    end

    it "403s if a customer is logged in" do
      login_as(customer)
      post "/v1/me/reset_password", token: code.token, password: "new-password"
      expect(last_response).to have_status(403)
    end
  end
end
