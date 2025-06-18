# frozen_string_literal: true

require "suma/admin_api/organization_membership_verifications"
require "suma/api/behaviors"

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
      expect(last_response).to have_json_body.that_includes(items: have_same_ids_as(*objs))
    end

    it_behaves_like "an endpoint with pagination", download: false do
      let(:url) { "/v1/organization_membership_verifications" }
      def make_item(i)
        created = Time.now - i.days
        return Suma::Fixtures.organization_membership_verification.create(created_at: created)
      end
    end

    describe "headers" do
      it "includes an auth token, and an header indicating Front is enabled" do
        Suma::Frontapp.auth_token = "fake-testing-auth-token"

        get "/v1/organization_membership_verifications"

        expect(last_response).to have_status(200)
        expect(last_response.headers).to include("Suma-Events-Token")
        expect(last_response.headers).to include("Suma-Front-Enabled" => "1")
      ensure
        Suma::Frontapp.reset_configuration
      end

      it "does not include the Suma-Front-Enabled header if Front is not enabled" do
        get "/v1/organization_membership_verifications"

        expect(last_response).to have_status(200)
        expect(last_response.headers).to_not include("Suma-Front-Enabled")
      end
    end

    describe "status parameter" do
      it "returns all memberships if 'all'" do
        m1 = Suma::Fixtures.organization_membership_verification.create
        m2 = Suma::Fixtures.organization_membership_verification.create(status: "ineligible")

        get "/v1/organization_membership_verifications", status: "all"

        expect(last_response).to have_status(200)
        expect(last_response).to have_json_body.that_includes(items: have_same_ids_as(m1, m2))
      end

      it "returns actionable memberships if 'todo'" do
        m1 = Suma::Fixtures.organization_membership_verification.create
        m2 = Suma::Fixtures.organization_membership_verification.create(status: "in_progress")
        Suma::Fixtures.organization_membership_verification.create(status: "ineligible")

        get "/v1/organization_membership_verifications", status: "todo"

        expect(last_response).to have_status(200)
        expect(last_response).to have_json_body.that_includes(items: have_same_ids_as(m1, m2))
      end

      it "filters to the status value otherwise" do
        Suma::Fixtures.organization_membership_verification.create
        m = Suma::Fixtures.organization_membership_verification.create(status: "ineligible")
        Suma::Fixtures.organization_membership_verification.create(status: "abandoned")

        get "/v1/organization_membership_verifications", status: "ineligible"
        expect(last_response).to have_status(200)
        expect(last_response).to have_json_body.that_includes(items: have_same_ids_as(m))
      end
    end

    describe "order parameter" do
      it "can order by status" do
        m1 = Suma::Fixtures.organization_membership_verification.create(status: "abandoned")
        m2 = Suma::Fixtures.organization_membership_verification.create(status: "in_progress")

        get "/v1/organization_membership_verifications", status: "all", order_by: "status", order_direction: "desc"
        expect(last_response).to have_status(200)
        expect(last_response).to have_json_body.that_includes(items: have_same_ids_as(m2, m1).ordered)

        get "/v1/organization_membership_verifications", status: "all", order_by: "status", order_direction: "asc"
        expect(last_response).to have_status(200)
        expect(last_response).to have_json_body.that_includes(items: have_same_ids_as(m1, m2).ordered)
      end

      it "can order by member name" do
        m1 = Suma::Fixtures.organization_membership_verification.create
        m1.membership.member.update(name: "Abc")
        m2 = Suma::Fixtures.organization_membership_verification.create
        m2.membership.member.update(name: "Xyz")

        get "/v1/organization_membership_verifications", order_by: "member", order_direction: "desc"
        expect(last_response).to have_status(200)
        expect(last_response).to have_json_body.that_includes(items: have_same_ids_as(m2, m1).ordered)

        get "/v1/organization_membership_verifications", order_by: "member", order_direction: "asc"
        expect(last_response).to have_status(200)
        expect(last_response).to have_json_body.that_includes(items: have_same_ids_as(m1, m2).ordered)
      end

      it "can order by organization name, across unverified, verified, and former org names" do
        m1 = Suma::Fixtures.organization_membership_verification.create
        m1.membership.update(unverified_organization_name: "Abc")
        m2 = Suma::Fixtures.organization_membership_verification.create
        m2.membership.update(verified_organization: Suma::Fixtures.organization.create(name: "Lmn"))
        m3 = Suma::Fixtures.organization_membership_verification.create
        m3.membership.update(verified_organization: Suma::Fixtures.organization.create(name: "Xyz"))
        m3.membership.remove_from_organization

        get "/v1/organization_membership_verifications", order_by: "organization", order_direction: "asc"
        expect(last_response).to have_status(200)
        expect(last_response).to have_json_body.that_includes(items: have_same_ids_as(m1, m2, m3).ordered)

        get "/v1/organization_membership_verifications", order_by: "organization", order_direction: "desc"
        expect(last_response).to have_status(200)
        expect(last_response).to have_json_body.that_includes(items: have_same_ids_as(m3, m2, m1).ordered)
      end

      it "can order by verification created at" do
        m1 = Suma::Fixtures.organization_membership_verification.create
        m2 = Suma::Fixtures.organization_membership_verification.create

        get "/v1/organization_membership_verifications", order_by: "created_at", order_direction: "desc"
        expect(last_response).to have_status(200)
        expect(last_response).to have_json_body.that_includes(items: have_same_ids_as(m2, m1).ordered)

        get "/v1/organization_membership_verifications", order_by: "created_at", order_direction: "asc"
        expect(last_response).to have_status(200)
        expect(last_response).to have_json_body.that_includes(items: have_same_ids_as(m1, m2).ordered)
      end
    end

    describe "search" do
      it "searches member and orgs names" do
        m1 = Suma::Fixtures.organization_membership_verification.create
        m1.membership.update(unverified_organization_name: "James")
        m1.membership.member.update(name: "John")

        m2 = Suma::Fixtures.organization_membership_verification.create
        m2.membership.update(verified_organization: Suma::Fixtures.organization.create(name: "Lmn"))
        m2.membership.member.update(name: "John")

        m3 = Suma::Fixtures.organization_membership_verification.create
        m3.membership.update(verified_organization: Suma::Fixtures.organization.create(name: "Xyz"))
        m3.membership.remove_from_organization
        m3.membership.member.update(name: "James")

        get "/v1/organization_membership_verifications", search: "James"
        expect(last_response).to have_status(200)
        expect(last_response).to have_json_body.that_includes(items: have_same_ids_as(m1, m3))
      end
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
    let(:v) { Suma::Fixtures.organization_membership_verification.create }

    it "transitions the verification" do
      header "Suma-Events-Token", "abc"
      post "/v1/organization_membership_verifications/#{v.id}/transition", event: "start"

      expect(last_response).to have_status(200)
      expect(v.refresh).to have_attributes(status: "in_progress")
    end

    it "400s if the transition fails" do
      v = Suma::Fixtures.organization_membership_verification.create

      header "Suma-Events-Token", "abc"
      post "/v1/organization_membership_verifications/#{v.id}/transition", event: "reject"

      expect(last_response).to have_status(400)
      expect(last_response_json_body).to include(error: include(message: "Could not reject verification"))
    end

    it "403s if the item does not exist" do
      header "Suma-Events-Token", "abc"
      post "/v1/organization_membership_verifications/0/transition", event: "start"

      expect(last_response).to have_status(403)
    end

    it "errors without role access" do
      replace_roles(admin, Suma::Role.cache.noop_admin)

      header "Suma-Events-Token", "abc"
      post "/v1/organization_membership_verifications/#{v.id}/transition", event: "start"

      expect(last_response).to have_status(403)
      expect(last_response).to have_json_body.that_includes(error: include(code: "role_check"))
    end

    it "400s for a missing events token header" do
      post "/v1/organization_membership_verifications/#{v.id}/transition", event: "start"

      expect(last_response).to have_status(400)
      expect(last_response).to have_json_body.that_includes(error: include(code: "missing_sse_token"))
    end
  end

  describe "POST /v1/organization_membership_verifications/:id/begin_partner_outreach",
           reset_configuration: Suma::Organization::Membership::Verification do
    before(:each) do
      Suma::Organization::Membership::Verification.front_partner_channel_id = "ch123"
    end

    let(:v) { Suma::Fixtures.organization_membership_verification.create }

    it "begins partner outreach" do
      teammate_req = stub_request(:get, "https://api2.frontapp.com/teammates/alt:email:#{admin.email}").
        to_return(json_response(load_fixture_data("front/teammate")))
      draft_req = stub_request(:post, "https://api2.frontapp.com/channels/ch123/drafts").
        to_return(json_response(load_fixture_data("front/channel_create_draft")))

      header "Suma-Events-Token", "abc"
      post "/v1/organization_membership_verifications/#{v.id}/begin_partner_outreach"

      expect(last_response).to have_status(200)
      expect(teammate_req).to have_been_made
      expect(draft_req).to have_been_made
      expect(v.refresh).to have_attributes(partner_outreach_front_conversation_id: "cnv_yo1kg5q")
    end

    it "400s for a missing events token header" do
      post "/v1/organization_membership_verifications/#{v.id}/begin_partner_outreach"

      expect(last_response).to have_status(400)
      expect(last_response).to have_json_body.that_includes(error: include(code: "missing_sse_token"))
    end
  end

  describe "POST /v1/organization_membership_verifications/:id/begin_member_outreach",
           reset_configuration: Suma::Organization::Membership::Verification do
    before(:each) do
      Suma::Organization::Membership::Verification.front_member_channel_id = "ch123"
    end

    let(:v) { Suma::Fixtures.organization_membership_verification.create }

    it "begins member outreach" do
      teammate_req = stub_request(:get, "https://api2.frontapp.com/teammates/alt:email:#{admin.email}").
        to_return(json_response(load_fixture_data("front/teammate")))
      draft_req = stub_request(:post, "https://api2.frontapp.com/channels/ch123/drafts").
        to_return(json_response(load_fixture_data("front/channel_create_draft")))

      header "Suma-Events-Token", "abc"
      post "/v1/organization_membership_verifications/#{v.id}/begin_member_outreach"

      expect(last_response).to have_status(200)
      expect(teammate_req).to have_been_made
      expect(draft_req).to have_been_made
      expect(v.refresh).to have_attributes(member_outreach_front_conversation_id: "cnv_yo1kg5q")
    end

    it "400s for a missing events token header" do
      post "/v1/organization_membership_verifications/#{v.id}/begin_member_outreach"

      expect(last_response).to have_status(400)
      expect(last_response).to have_json_body.that_includes(error: include(code: "missing_sse_token"))
    end
  end

  describe "POST /v1/organization_membership_verifications/:id/notes" do
    let(:v) { Suma::Fixtures.organization_membership_verification.create }

    it "creates a note" do
      header "Suma-Events-Token", "abc"
      post "/v1/organization_membership_verifications/#{v.id}/notes", content: "hello"

      expect(last_response).to have_status(200)
      expect(v.refresh.notes).to contain_exactly(
        have_attributes(
          content: "hello",
          creator: be === admin,
          created_at: match_time(:now),
          editor: nil,
          edited_at: nil,
        ),
      )
    end

    it "400s for a missing events token header" do
      post "/v1/organization_membership_verifications/#{v.id}/notes", content: "hello"

      expect(last_response).to have_status(400)
      expect(last_response).to have_json_body.that_includes(error: include(code: "missing_sse_token"))
    end
  end

  describe "POST /v1/organization_membership_verifications/:id/notes/:id" do
    let(:v) { Suma::Fixtures.organization_membership_verification.create }
    let(:other_admin) { Suma::Fixtures.member.create }
    let(:created_at) { 5.hours.ago }
    let(:note) { v.add_note(content: "hello", creator: other_admin, created_at:) }

    it "edits a note" do
      header "Suma-Events-Token", "abc"
      post "/v1/organization_membership_verifications/#{v.id}/notes/#{note.id}", content: "bye"

      expect(last_response).to have_status(200)
      expect(v.refresh.notes).to contain_exactly(
        have_attributes(
          content: "bye",
          creator: be === other_admin,
          created_at: match_time(created_at),
          editor: be === admin,
          edited_at: match_time(:now),
        ),
      )
    end

    it "403s for an invalid id" do
      header "Suma-Events-Token", "abc"
      post "/v1/organization_membership_verifications/#{v.id}/notes/0", content: "hello"

      expect(last_response).to have_status(403)
    end

    it "400s for a missing events token header" do
      post "/v1/organization_membership_verifications/#{v.id}/notes/#{note.id}", content: "bye"

      expect(last_response).to have_status(400)
      expect(last_response).to have_json_body.that_includes(error: include(code: "missing_sse_token"))
    end
  end
end
