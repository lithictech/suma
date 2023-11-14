# frozen_string_literal: true

require "suma/admin_api/eligibility_constraints"
require "suma/api/behaviors"

RSpec.describe Suma::AdminAPI::EligibilityConstraints, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create }

  before(:each) do
    login_as_admin(admin)
  end

  describe "GET /v1/eligibility_constraints" do
    it "returns all eligibility constraints" do
      objs = Array.new(2) { Suma::Fixtures.eligibility_constraint.create }

      get "/v1/eligibility_constraints"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(items: have_same_ids_as(*objs))
    end

    it_behaves_like "an endpoint capable of search" do
      let(:url) { "/v1/eligibility_constraints" }
      let(:search_term) { "Lime" }

      def make_matching_items
        return [
          Suma::Fixtures.eligibility_constraint(name: "Lime eScooters").create,
        ]
      end

      def make_non_matching_items
        return [
          Suma::Fixtures.eligibility_constraint(name: translated_text("wibble wobble")).create,
        ]
      end
    end

    it_behaves_like "an endpoint with pagination" do
      let(:url) { "/v1/eligibility_constraints" }
      def make_item(i)
        # Sorting is newest first, so the first items we create need to the the oldest.
        created = Time.now - i.days
        return Suma::Fixtures.eligibility_constraint.create(created_at: created)
      end
    end

    it_behaves_like "an endpoint with member-supplied ordering" do
      let(:url) { "/v1/eligibility_constraints" }
      let(:order_by_field) { "id" }
      def make_item(_i)
        return Suma::Fixtures.eligibility_constraint.create(
          created_at: Time.now + rand(1..100).days,
        )
      end
    end
  end

  describe "POST /v1/eligibility_constraints/create" do
    it "creates the constraint" do
      post "/v1/eligibility_constraints/create", name: "Test constraint"

      expect(last_response).to have_status(200)
      expect(last_response.headers).to include("Created-Resource-Admin")
      expect(Suma::Eligibility::Constraint.all).to have_length(1)
    end
  end

  describe "GET /v1/eligibility_constraints/:id" do
    it "returns the eligibility constraint" do
      ec = Suma::Fixtures.eligibility_constraint.create
      offering_objs = Array.new(2) { Suma::Fixtures.offering.with_constraints(ec).create }
      vendor_service_objs = Array.new(2) { Suma::Fixtures.vendor_service.with_constraints(ec).create }
      configuration_objs = Array.new(2) { Suma::Fixtures.anon_proxy_vendor_configuration.with_constraints(ec).create }

      get "/v1/eligibility_constraints/#{ec.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        id: ec.id,
        offerings: have_same_ids_as(*offering_objs),
        services: have_same_ids_as(*vendor_service_objs),
        configurations: have_same_ids_as(*configuration_objs),
      )
    end

    it "403s if the item does not exist" do
      get "/v1/eligibility_constraints/0"

      expect(last_response).to have_status(403)
    end
  end
end
