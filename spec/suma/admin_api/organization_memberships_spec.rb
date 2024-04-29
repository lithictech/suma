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
      memberships = Array.new(2) { Suma::Fixtures.organization_membership.unverified.create }
      get "/v1/organization_memberships"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(items: have_same_ids_as(*memberships))
    end
  end

  describe "GET /v1/organization_memberships/:id" do
    it "returns an organization membership" do
      membership = Suma::Fixtures.organization_membership.verified.create

      get "/v1/organization_memberships/#{membership.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: membership.id)
    end

    it "403s if the item does not exist" do
      get "/v1/organization_memberships/0"

      expect(last_response).to have_status(403)
    end
  end

  describe "POST /v1/organization_memberships/create" do
    it "creates a verified organization membership" do
      org = Suma::Fixtures.organization.create

      post "/v1/organization_memberships/create",
           member: {id: admin.id},
           verified_organization: {id: org.id}

      expect(last_response).to have_status(200)
      expect(last_response.headers).to include("Created-Resource-Admin")
      expect(Suma::Organization::Membership.all).to contain_exactly(
        have_attributes(verified_organization: include(id: org.id), member: include(id: admin.id)),
      )
    end

    it "creates an unverified organization membership" do
      org = Suma::Fixtures.organization.create

      post "/v1/organization_memberships/create",
           member: {id: admin.id},
           unverified_organization_name: "xyz"

      expect(last_response).to have_status(200)
      expect(Suma::Organization::Membership.all).to contain_exactly(
        have_attributes(unverified_organization_name: "xyz"),
      )
    end
  end

  describe "POST /v1/organization_memberships/:id" do
    it "updates an organization membership" do
      membership = Suma::Fixtures.organization_membership.unverified.create
      new_org = Suma::Fixtures.organization.create

      post "/v1/organization_memberships/#{membership.id}",
           member: {id: admin.id, name: "abc"},
           verified_organization: {id: new_org.id}

      expect(last_response).to have_status(200)
      expect(membership.refresh).to have_attributes(member: admin, verified_organization: new_org)
    end
  end
end
