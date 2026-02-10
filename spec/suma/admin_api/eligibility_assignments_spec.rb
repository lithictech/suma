# frozen_string_literal: true

require "suma/admin_api/eligibility_assignments"
require "suma/api/behaviors"

RSpec.describe Suma::AdminAPI::EligibilityAssignments, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create }

  before(:each) do
    login_as(admin)
  end

  describe "GET /v1/eligibility_assignments" do
    it "returns all instances" do
      objs = Array.new(2) { Suma::Fixtures.eligibility_assignment.create }

      get "/v1/eligibility_assignments"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(items: have_same_ids_as(*objs))
    end

    it_behaves_like "an endpoint capable of search" do
      let(:url) { "/v1/eligibility_assignments" }
      let(:search_term) { "zzz" }

      def make_matching_items
        return [
          Suma::Fixtures.eligibility_assignment.create(member: Suma::Fixtures.member.named("zzz").create).create,
        ]
      end

      def make_non_matching_items
        return [
          Suma::Fixtures.eligibility_assignment.create(member: Suma::Fixtures.member.named("wibble").create).create,
        ]
      end
    end
  end

  describe "POST /v1/eligibility_assignments/create" do
    let(:attr) { Suma::Fixtures.eligibility_attribute.create }

    it "creates the assignment for member" do
      member = Suma::Fixtures.member.create

      post "/v1/eligibility_assignments/create", attribute: {id: attr.id}, member: {id: member.id}

      expect(last_response).to have_status(200)
      expect(last_response.headers).to include("Created-Resource-Admin")
      expect(Suma::Eligibility::Assignment.all).to have_length(1)
    end

    it "creates the assignment for organization" do
      organization = Suma::Fixtures.organization.create

      post "/v1/eligibility_assignments/create", attribute: {id: attr.id}, organization: {id: organization.id}

      expect(last_response).to have_status(200)
      expect(last_response.headers).to include("Created-Resource-Admin")
      expect(Suma::Eligibility::Assignment.all).to have_length(1)
    end

    it "creates the assignment for role" do
      role = Suma::Role.create(name: "test")

      post "/v1/eligibility_assignments/create", attribute: {id: attr.id}, role: {id: role.id}

      expect(last_response).to have_status(200)
      expect(last_response.headers).to include("Created-Resource-Admin")
      expect(Suma::Eligibility::Assignment.all).to have_length(1)
    end
  end

  describe "GET /v1/eligibility_assignments/:id" do
    it "returns the assignment" do
      assignment = Suma::Fixtures.eligibility_assignment.create

      get "/v1/eligibility_assignments/#{assignment.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        id: assignment.id,
        assignee: include(id: assignment.assignee.id),
      )
    end

    it "403s if the item does not exist" do
      get "/v1/eligibility_assignments/0"

      expect(last_response).to have_status(403)
    end
  end

  describe "POST /v1/eligibility_assignments/:id/destroy" do
    it "destroys the resource" do
      m = Suma::Fixtures.eligibility_assignment.create

      post "/v1/eligibility_assignments/#{m.id}/destroy"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: m.id)
      expect(m).to be_destroyed
    end
  end
end
