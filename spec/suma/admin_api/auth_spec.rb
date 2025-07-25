# frozen_string_literal: true

require "suma/admin_api/auth"

RSpec.describe Suma::AdminAPI::Auth, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:password) { "Password1!" }
  let(:member) { Suma::Fixtures.member.create(password:) }
  let(:admin) { Suma::Fixtures.member.admin.create(password:) }

  describe "GET /v1/auth" do
    it "200s if the member is an admin and authed as an admin" do
      login_as(admin)

      get "/v1/auth"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: admin.id, impersonating: nil)
    end

    it "returns the admin member, even if impersonated" do
      login_as(admin)

      target = Suma::Fixtures.member.create
      post "/v1/auth/impersonate/#{target.id}"
      expect(last_response).to have_status(200)

      get "/v1/auth"
      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(id: admin.id, impersonating: include(id: target.id))
    end

    it "401s if the member is not authed" do
      get "/v1/auth"

      expect(last_response).to have_status(401)
    end

    it "401s if the member has authed as an admin but no longer has admin access" do
      login_as(admin)
      admin.remove_role(Suma::Role.cache.admin)

      get "/v1/auth"

      expect(last_response).to have_status(401)
    end
  end

  describe "POST /v1/auth" do
    it "errors if a member is already authed" do
      login_as(admin)

      post("/v1/auth", email: admin.email, password:)

      expect(last_response).to have_status(409)
      expect(last_response).to have_json_body.
        that_includes(error: include(message: "You are already signed in. Please sign out first."))
    end

    it "errors if the member is not an admin" do
      post("/v1/auth", email: member.email, password:)

      expect(last_response).to have_status(403)
      expect(last_response).to have_json_body.
        that_includes(error: include(code: "role_check"))
    end

    it "returns 200 and creates a session if the email and password are valid" do
      post("/v1/auth", email: admin.email, password:)

      expect(last_response).to have_status(200)
      expect(last_response).to have_session_cookie.with_payload_key("warden.user.member.key")
      expect(last_response).to have_json_body.that_includes(id: admin.id)
    end

    it "returns 403 if the email does not map to a member" do
      post("/v1/auth", email: admin.email + "x", password:)

      expect(last_response).to have_status(403)
      expect(last_response).to have_json_body.that_includes(error: include(code: "invalid_credentials"))
    end

    it "returns 403 if the password is not valid" do
      post("/v1/auth", email: admin.email, password: "password")

      expect(last_response).to have_status(403)
      expect(last_response).to have_json_body.that_includes(error: include(code: "invalid_credentials"))
    end
  end

  describe "DELETE /v1/auth" do
    it "removes the cookies and marks the session deleted" do
      login_as(admin)

      delete "/v1/auth"

      expect(last_response).to have_status(204)
      expect(last_response["Set-Cookie"]).to include("=; path=/; max-age=0; expires=Thu, 01 Jan 1970 00:00:00")
      expect(last_response["Clear-Site-Data"]).to eq("*")
      expect(admin.sessions_dataset.last).to be_logged_out
    end
  end

  describe "POST /v1/auth/impersonate/:id" do
    let(:target) { Suma::Fixtures.member.create }

    it "impersonates the given member" do
      login_as(admin)

      post "/v1/auth/impersonate/#{target.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(id: admin.id,  impersonating: include(id: target.id))
    end

    it "replaces an existing impersonated member" do
      login_as(admin)
      post "/v1/auth/impersonate/#{target.id}"

      other_target = Suma::Fixtures.member.create
      post "/v1/auth/impersonate/#{other_target.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(id: admin.id,  impersonating: include(id: other_target.id))
    end

    it "403s if the member does not exist" do
      login_as(admin)

      post "/v1/auth/impersonate/0"

      expect(last_response).to have_status(403)
    end

    it "401s if the authed member is not an admin" do
      login_as(target)

      post "/v1/auth/impersonate/#{target.id}"

      expect(last_response).to have_status(401)
    end

    it "403s if the authed member does not have the ability to impersonate" do
      admin.remove_role(Suma::Role.cache.admin)
      admin.add_role(Suma::Role.cache.readonly_admin)
      login_as(admin)

      post "/v1/auth/impersonate/#{target.id}"

      expect(last_response).to have_status(403)
      expect(last_response).to have_json_body.that_includes(error: include(code: "role_check"))
    end
  end

  describe "DELETE /v1/auth/impersonate" do
    it "unimpersonates an impersonated member" do
      login_as(admin)

      target = Suma::Fixtures.member.create
      post "/v1/auth/impersonate/#{target.id}"
      expect(last_response).to have_status(200)

      delete "/v1/auth/impersonate"
      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(id: admin.id,  impersonating: nil)
    end

    it "noops if no member is impersonated" do
      login_as(admin)

      delete "/v1/auth/impersonate"
      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(id: admin.id,  impersonating: nil)
    end

    it "401s if the authed member is not an admin" do
      login_as(Suma::Fixtures.member.create)

      delete "/v1/auth/impersonate"

      expect(last_response).to have_status(401)
    end
  end
end
