# frozen_string_literal: true

require "suma/admin_api/organization_memberships"

RSpec.describe Suma::AdminAPI::OrganizationMemberships, :db do
  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create }

  before(:each) do
    login_as_admin(admin)
  end

  describe "GET /v1/organization_memberships" do
    it "returns all organization memberships" do
      memberships = Array.new(2) { Suma::Fixtures.organization_membership.create }
      get "/v1/organization_memberships"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(items: have_same_ids_as(*memberships))
    end
  end

  describe "GET /v1/organization_memberships/:id" do
    it "returns an organization membership" do
      member = Suma::Fixtures.member.create
      org = Suma::Fixtures.organization.create
      membership = Suma::Fixtures.organization_membership(member:, organization: org).create

      get "/v1/organization_memberships/#{membership.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        id: membership.id,
        member: include(id: member.id),
        organization: include(id: org.id),
      )
    end

    it "403s if the item does not exist" do
      get "/v1/organization_memberships/0"

      expect(last_response).to have_status(403)
    end
  end

  describe "POST /v1/organization_memberships/create" do
    it "creates the organization membership" do
      org = Suma::Fixtures.organization.create

      post "/v1/organization_memberships/create",
           member: {id: admin.id},
           organization: {id: org.id}

      expect(last_response).to have_status(200)
      expect(last_response.headers).to include("Created-Resource-Admin")
      expect(Suma::Organization::Membership.all).to have_length(1)
    end
  end

  describe "POST /v1/organization_memberships/:id" do
    it "updates an organization membership" do
      membership = Suma::Fixtures.organization_membership.create
      new_org = Suma::Fixtures.organization.create

      post "/v1/organization_memberships/#{membership.id}",
           member: {id: admin.id, name: "abc"},
           organization: {id: new_org.id}

      expect(last_response).to have_status(200)
      expect(membership.refresh).to have_attributes(member: admin, organization: new_org)
    end
  end
end
