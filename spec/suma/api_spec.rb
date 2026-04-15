# frozen_string_literal: true

require "rack/test"

require "suma/api"

class Suma::API::TestV1API < Suma::API::V1
  get :current_member_header do
    add_current_member_header if params[:inheader]
    body "ok"
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
end
