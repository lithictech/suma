# frozen_string_literal: true

require "suma/admin_api/organizations"
require "suma/api/behaviors"

RSpec.describe Suma::AdminAPI::Organizations, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create }

  before(:each) do
    login_as(admin)
  end

  describe "GET /v1/organizations" do
    it "returns all organizations" do
      orgs = Array.new(2) { Suma::Fixtures.organization.create }
      get "/v1/organizations"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(items: have_same_ids_as(*orgs))
    end

    it_behaves_like "an endpoint capable of search" do
      let(:url) { "/v1/organizations" }
      let(:search_term) { "zzz" }

      def make_matching_items
        return [
          Suma::Fixtures.organization(name: "zzz ABC").create,
        ]
      end

      def make_non_matching_items
        return [
          Suma::Fixtures.organization(name: translated_text("wibble wobble")).create,
        ]
      end
    end

    it_behaves_like "an endpoint with pagination" do
      let(:url) { "/v1/organizations" }
      def make_item(i)
        # Sorting is newest first, so the first items we create need to the the oldest.
        created = Time.now - i.days
        return Suma::Fixtures.organization.create(created_at: created)
      end
    end

    it_behaves_like "an endpoint with member-supplied ordering" do
      let(:url) { "/v1/organizations" }
      let(:order_by_field) { "id" }
      def make_item(_i)
        return Suma::Fixtures.organization.create(
          created_at: Time.now + rand(1..100).days,
        )
      end
    end
  end

  describe "POST /v1/organizations/create" do
    it "creates a organization" do
      post "/v1/organizations/create", name: "Hacienda"

      expect(last_response).to have_status(200)
      expect(Suma::Organization.all).to have_length(1)
    end
  end

  describe "GET /v1/organizations/:id" do
    it "returns the organization" do
      organization = Suma::Fixtures.organization.create
      membership = Suma::Fixtures.organization_membership.verified(organization).create

      get "/v1/organizations/#{organization.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        id: organization.id,
        memberships: have_same_ids_as(membership),
      )
    end

    it "403s if the item does not exist" do
      get "/v1/organizations/0"

      expect(last_response).to have_status(403)
    end
  end

  describe "POST /v1/organizations/:id" do
    it "updates an organization" do
      org = Suma::Fixtures.organization.create

      post "/v1/organizations/#{org.id}", name: "hacienda abc"

      expect(last_response).to have_status(200)
      expect(org.refresh).to have_attributes(name: "hacienda abc")
    end

    it "replaces roles if given" do
      existing = Suma::Role.create(name: "existing")
      to_remove = Suma::Role.create(name: "to_remove")
      to_add = Suma::Role.create(name: "to_add")
      org = Suma::Fixtures.organization.create
      org.add_role(existing)
      org.add_role(to_remove)

      post "/v1/organizations/#{org.id}", roles: [{id: existing.id}, {id: to_add.id}]

      expect(last_response).to have_status(200)
      expect(org.refresh.roles.map(&:name)).to contain_exactly("existing", "to_add")
      expect(org.refresh.audit_activities).to contain_exactly(have_attributes(message_name: "rolechange"))
    end
  end
end
