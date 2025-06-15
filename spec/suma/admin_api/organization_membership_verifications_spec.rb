# frozen_string_literal: true

require "suma/admin_api/organization_membership_verifications"

RSpec.describe Suma::AdminAPI::OrganizationMembershipVerifications, :db do
  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create }

  before(:each) do
    login_as(admin)
  end

  describe "GET /v1/organization_membership_verifications" do
    it "returns all organization memberships" do
      objs = Array.new(2) { Suma::Fixtures.organization_membership_verification.create }
      get "/v1/organization_membership_verifications"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(items: have_same_ids_as(*objs))
    end
  end

  describe "GET /v1/organization_membership_verifications/todo" do
    it "returns actionable organization memberships" do
      m1 = Suma::Fixtures.organization_membership_verification.create
      m2 = Suma::Fixtures.organization_membership_verification.create(status: "ineligible")

      get "/v1/organization_membership_verifications/todo"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(items: have_same_ids_as(m1))
    end
  end

  describe "GET /v1/organization_membership_verifications/:id" do
    it "returns an organization membership" do
      v = Suma::Fixtures.organization_membership_verification.create

      get "/v1/organization_membership_verifications/#{v.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: v.id)
    end

    it "403s if the item does not exist" do
      get "/v1/organization_membership_verifications/0"

      expect(last_response).to have_status(403)
    end
  end

  describe "POST /v1/organization_membership_verifications/:id/transition" do
    it "transitions the verification" do
      v = Suma::Fixtures.organization_membership_verification.create

      post "/v1/organization_membership_verifications/#{v.id}/transition", event: "start"

      expect(last_response).to have_status(200)
      expect(v.refresh).to have_attributes(status: "in_progress")
    end

    it "400s if the transition fails" do
      v = Suma::Fixtures.organization_membership_verification.create

      post "/v1/organization_membership_verifications/#{v.id}/transition", event: "reject"

      expect(last_response).to have_status(400)
      expect(last_response_json_body).to include(error: include(message: "Could not reject verification"))
    end

    it "403s if the item does not exist" do
      post "/v1/organization_membership_verifications/0/transition", event: "start"

      expect(last_response).to have_status(403)
    end

    it "errors without role access" do
      replace_roles(admin, Suma::Role.cache.noop_admin)
      v = Suma::Fixtures.organization_membership_verification.create

      post "/v1/organization_membership_verifications/#{v.id}/transition", event: "start"

      expect(last_response).to have_status(403)
      expect(last_response).to have_json_body.that_includes(error: include(code: "role_check"))
    end
  end

  describe "POST /v1/organization_membership_verifications/:id/begin_partner_outreach",
           reset_configuration: Suma::Organization::MembershipVerification do
    before(:each) do
      Suma::Organization::MembershipVerification.front_partner_channel_id = "ch123"
    end

    it "begins partner outreach" do
      v = Suma::Fixtures.organization_membership_verification.create
      req = stub_request(:post, "https://api2.frontapp.com/channels/ch123/drafts").
        to_return(json_response(load_fixture_data("front/channel_create_draft")))

      post "/v1/organization_membership_verifications/#{v.id}/begin_partner_outreach"

      expect(last_response).to have_status(200)
      expect(req).to have_been_made
      expect(v.refresh).to have_attributes(partner_outreach_front_conversation_id: "cnv_yo1kg5q")
    end
  end

  describe "POST /v1/organization_membership_verifications/:id/begin_member_outreach",
           reset_configuration: Suma::Organization::MembershipVerification do
    before(:each) do
      Suma::Organization::MembershipVerification.front_member_channel_id = "ch123"
    end

    it "begins member outreach" do
      v = Suma::Fixtures.organization_membership_verification.create
      req = stub_request(:post, "https://api2.frontapp.com/channels/ch123/drafts").
        to_return(json_response(load_fixture_data("front/channel_create_draft")))

      post "/v1/organization_membership_verifications/#{v.id}/begin_member_outreach"

      expect(last_response).to have_status(200)
      expect(req).to have_been_made
      expect(v.refresh).to have_attributes(member_outreach_front_conversation_id: "cnv_yo1kg5q")
    end
  end
end
