# frozen_string_literal: true

require "suma/admin_api/organization_memberships"
require "suma/api/behaviors"

RSpec.describe Suma::AdminAPI::OrganizationMemberships, :db do
  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create(email: "z@mysuma.org") }

  before(:each) do
    login_as(admin)
  end

  describe "GET /v1/organization_memberships" do
    it "returns all organization memberships" do
      memberships = Array.new(2) { Suma::Fixtures.organization_membership.unverified.create }
      get "/v1/organization_memberships"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(items: have_same_ids_as(*memberships))
    end

    it_behaves_like "an endpoint capable of search" do
      let(:url) { "/v1/organization_memberships" }
      let(:search_term) { "zzz" }

      def make_matching_items
        return [
          Suma::Fixtures.organization_membership.unverified("zzz").create,
        ]
      end

      def make_non_matching_items
        return [
          Suma::Fixtures.organization_membership.unverified("wibble").create,
        ]
      end
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
    let(:member) { Suma::Fixtures.member.create(name: "Someone") }

    # rubocop:disable Layout/LineLength
    it "creates a verified organization membership" do
      org = Suma::Fixtures.organization.create(name: "MyOrg")

      post "/v1/organization_memberships/create",
           member: {id: member.id},
           verified_organization: {id: org.id}

      expect(last_response).to have_status(200)
      expect(last_response.headers).to include("Created-Resource-Admin")
      expect(Suma::Organization::Membership.all).to contain_exactly(
        have_attributes(verified_organization: include(id: org.id), member: include(id: member.id)),
      )
      expect(member.audit_activities).to contain_exactly(
        have_attributes(
          summary: "z@mysuma.org performed createmembership on Suma::Member[#{member.id}] 'Someone': Suma::Organization[#{org.id}] 'MyOrg'",
        ),
      )
      expect(org.audit_activities).to contain_exactly(
        have_attributes(
          summary: "z@mysuma.org performed addmember on Suma::Organization[#{org.id}] 'MyOrg': Suma::Member[#{member.id}] 'Someone'",
        ),
      )
    end

    it "creates an unverified organization membership" do
      post "/v1/organization_memberships/create",
           member: {id: member.id},
           unverified_organization_name: "xyz"

      expect(last_response).to have_status(200)
      expect(Suma::Organization::Membership.all).to contain_exactly(
        have_attributes(unverified_organization_name: "xyz"),
      )
      expect(member.audit_activities).to contain_exactly(
        have_attributes(
          summary: "z@mysuma.org performed createmembership on Suma::Member[#{member.id}] 'Someone': Unverified Org: xyz",
        ),
      )
    end
    # rubocop:enable Layout/LineLength
  end

  describe "POST /v1/organization_memberships/:id" do
    it "can update the unverified name" do
      membership = Suma::Fixtures.organization_membership.unverified.create

      post "/v1/organization_memberships/#{membership.id}", unverified_organization_name: "new name"

      expect(last_response).to have_status(200)
      expect(membership.refresh).to have_attributes(unverified_organization_name: "new name")
      expect(membership.member.audit_activities).to be_empty
    end

    it "updates an organization membership from unverified to verified" do
      membership = Suma::Fixtures.organization_membership.unverified.create
      new_org = Suma::Fixtures.organization.create

      post "/v1/organization_memberships/#{membership.id}", verified_organization: {id: new_org.id}

      expect(last_response).to have_status(200)
      expect(membership.refresh).to have_attributes(verified_organization: new_org)
      expect(membership.verified_organization.audit_activities).to contain_exactly(
        have_attributes(summary: /performed addmember /),
      )
      expect(membership.member.audit_activities).to contain_exactly(
        have_attributes(summary: /performed beginmembership /),
      )
    end
  end

  it "updates from verified to removed" do
    membership = Suma::Fixtures.organization_membership.verified.create

    post "/v1/organization_memberships/#{membership.id}", remove_from_organization: true

    expect(last_response).to have_status(200)
    expect(membership.refresh).to have_attributes(former_organization: be_present, verified_organization: nil)
    expect(membership.former_organization.audit_activities).to contain_exactly(
      have_attributes(summary: /performed removemember /),
    )
    expect(membership.member.audit_activities).to contain_exactly(
      have_attributes(summary: /performed endmembership /),
    )
  end
end
