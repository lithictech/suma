# frozen_string_literal: true

require "suma/admin_api/eligibility_constraints"

RSpec.describe Suma::AdminAPI::EligibilityConstraints, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create }

  before(:each) do
    login_as_admin(admin)
  end

  describe "GET /v1/constraints" do
    it "returns all eligibility constraints" do
      objs = Array.new(2) { Suma::Fixtures.eligibility_constraint.create }

      get "/v1/constraints"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(items: have_same_ids_as(*objs))
    end

    it_behaves_like "an endpoint capable of search" do
      let(:url) { "/v1/constraints" }
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
      let(:url) { "/v1/constraints" }
      def make_item(i)
        # Sorting is newest first, so the first items we create need to the the oldest.
        created = Time.now - i.days
        return Suma::Fixtures.eligibility_constraint.create(created_at: created)
      end
    end

    it_behaves_like "an endpoint with member-supplied ordering" do
      let(:url) { "/v1/constraints" }
      let(:order_by_field) { "id" }
      def make_item(_i)
        return Suma::Fixtures.eligibility_constraint.create(
          created_at: Time.now + rand(1..100).days,
        )
      end
    end
  end

  describe "POST /v1/constraints/create" do
    it "creates the constraint" do
      post "/v1/constraints/create", name: "Test constraint"

      expect(last_response).to have_status(200)
      expect(last_response.headers).to include("Created-Resource-Admin")
      expect(Suma::Eligibility::Constraint.all).to have_length(1)
    end

    it "403s if constraint already exists" do
      ec = Suma::Fixtures.eligibility_constraint.create
      post "/v1/constraints/create", name: ec.name

      expect(last_response).to have_status(403)
    end
  end

  describe "GET /v1/constraints/:id" do
    it "returns the eligibility constraint" do
      x = Suma::Fixtures.eligibility_constraint.create
      offering_objs = Array.new(2) { Suma::Fixtures.offering.with_constraints(x).create }
      vendor_service_objs = Array.new(2) { Suma::Fixtures.vendor_service.with_constraints(x).create }

      get "/v1/constraints/#{x.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        id: x.id,
        offerings: have_same_ids_as(*offering_objs),
        services: have_same_ids_as(*vendor_service_objs),
      )
    end

    it "403s if the item does not exist" do
      get "/v1/constraints/0"

      expect(last_response).to have_status(403)
    end
  end
end
