# frozen_string_literal: true

require "suma/admin_api/vendor_services"
require "suma/api/behaviors"

RSpec.describe Suma::AdminAPI::VendorServices, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create }

  before(:each) do
    login_as(admin)
  end

  describe "GET /v1/vendor_services" do
    it "returns all vendor services" do
      objs = Array.new(2) { Suma::Fixtures.vendor_service.create }

      get "/v1/vendor_services"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(items: have_same_ids_as(*objs))
    end

    it_behaves_like "an endpoint capable of search" do
      let(:url) { "/v1/vendor_services" }
      let(:search_term) { "demo" }

      def make_matching_items
        return [
          Suma::Fixtures.vendor_service(internal_name: "Demo Mobility Deeplink").create,
        ]
      end

      def make_non_matching_items
        return [
          Suma::Fixtures.vendor_service(internal_name: translated_text("wibble wobble")).create,
        ]
      end
    end

    it_behaves_like "an endpoint with pagination" do
      let(:url) { "/v1/vendor_services" }
      def make_item(i)
        # Sorting is newest first, so the first items we create need to the the oldest.
        created = Time.now - i.days
        return Suma::Fixtures.vendor_service.create(created_at: created)
      end
    end

    it_behaves_like "an endpoint with member-supplied ordering" do
      let(:url) { "/v1/vendor_services" }
      let(:order_by_field) { "id" }
      def make_item(_i)
        return Suma::Fixtures.vendor_service.create(
          created_at: Time.now + rand(1..100).days,
        )
      end
    end
  end

  describe "GET /v1/vendor_services/:id" do
    it "returns the vendor service" do
      vendor = Suma::Fixtures.vendor.create
      constraint = Suma::Fixtures.eligibility_constraint.create
      service = Suma::Fixtures.vendor_service.mobility.with_constraints(constraint).create(vendor:)
      rate = Suma::Fixtures.vendor_service_rate.surcharge.for_service(service).create
      trip = Suma::Fixtures.mobility_trip.create(vendor_service: service)

      get "/v1/vendor_services/#{service.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        id: service.id,
        vendor: include(id: vendor.id),
        eligibility_constraints: contain_exactly(include(id: constraint.id)),
        mobility_vendor_adapter_key: "fake",
        categories: contain_exactly(include(name: "Mobility")),
        rates: contain_exactly(include(id: rate.id)),
        mobility_trips: contain_exactly(include(id: trip.id)),
      )
    end

    it "403s if the item does not exist" do
      get "/v1/vendor_services/0"

      expect(last_response).to have_status(403)
    end
  end
end
