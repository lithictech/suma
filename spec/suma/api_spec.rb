# frozen_string_literal: true

require "rack/test"

require "suma/api"

class Suma::API::TestV1API < Suma::API::V1
  get :current_member_header do
    add_current_member_header if params[:inheader]
    body "ok"
  end

  post :call_stripe do
    Stripe::Charge.capture("ch_123")
  end
end

RSpec.describe Suma::API::V1, :db do
  include Rack::Test::Methods

  let(:app) { Suma::API::TestV1API.build_app }
  let(:member) { Suma::Fixtures.member.create }

  describe "current member header" do
    it "can be returned base64 encoded in a header" do
      login_as(member)
      get "/v1/current_member_header?inheader=true"
      expect(last_response).to have_status(200)
      expect(last_response.headers).to include("Suma-Current-Member")
      j = Base64.strict_decode64(last_response.headers["Suma-Current-Member"])
      m = JSON.parse(j)
      expect(m).to include("onboarded", "id" => member.id)
    end

    it "does not return the header unless the helper is called" do
      login_as(member)
      get "/v1/current_member_header"
      expect(last_response).to have_status(200)
      expect(last_response.headers).to_not include("Suma-Current-Member")
    end

    it "returns the right member when impersonated" do
      admin = Suma::Fixtures.member.admin.create
      login_as(admin)
      impersonate(admin:, target: member)
      get "/v1/current_member_header?inheader=true"
      expect(last_response).to have_status(200)
      expect(last_response.headers).to include("Suma-Current-Member")
      j = Base64.strict_decode64(last_response.headers["Suma-Current-Member"])
      m = JSON.parse(j)
      expect(m).to include("onboarded", "id" => member.id)
    end
  end

  describe "Stripe errors" do
    it "does not modify non-card errors" do
      req = stub_request(:post, "https://api.stripe.com/v1/charges/ch_123/capture").
        to_return(fixture_response("stripe/charge_error", status: 500))

      post "/v1/call_stripe"

      expect(req).to have_been_made
      expect(last_response).to have_status(500)
      expect(last_response).to have_json_body.that_includes(error: include(code: "api_error"))
    end

    it "coerces card errors into an error shape" do
      req = stub_request(:post, "https://api.stripe.com/v1/charges/ch_123/capture").
        to_return(fixture_response("stripe/charge_error", status: 402))

      post "/v1/call_stripe"

      expect(req).to have_been_made
      expect(last_response).to have_status(402)
      expect(last_response).to have_json_body.that_includes(error: include(code: "card_permanent_failure"))
    end
  end
end
