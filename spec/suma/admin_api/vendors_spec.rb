# frozen_string_literal: true

require "suma/admin_api/vendors"
require "suma/api/behaviors"

RSpec.describe Suma::AdminAPI::Vendors, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create }

  before(:each) do
    login_as_admin(admin)
  end

  describe "GET /v1/vendors" do
    it "returns all vendors" do
      objs = Array.new(2) { Suma::Fixtures.vendor.create }

      get "/v1/vendors"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(items: have_same_ids_as(*objs))
    end

    it_behaves_like "an endpoint capable of search" do
      let(:url) { "/v1/vendors" }
      let(:search_term) { "johns_farm" }

      def make_matching_items
        return [
          Suma::Fixtures.vendor(name: "Johns Farmers Market").create,
        ]
      end

      def make_non_matching_items
        return [
          Suma::Fixtures.vendor(name: translated_text("wibble wobble")).create,
        ]
      end
    end

    it_behaves_like "an endpoint with pagination" do
      let(:url) { "/v1/vendors" }
      def make_item(i)
        # Sorting is newest first, so the first items we create need to the the oldest.
        created = Time.now - i.days
        return Suma::Fixtures.vendor.create(created_at: created)
      end
    end

    it_behaves_like "an endpoint with member-supplied ordering" do
      let(:url) { "/v1/vendors" }
      let(:order_by_field) { "id" }
      def make_item(_i)
        return Suma::Fixtures.vendor.create(
          created_at: Time.now + rand(1..100).days,
        )
      end
    end
  end

  describe "POST /v1/vendors/create" do
    it "creates a vendor" do
      post "/v1/vendors/create", name: "test"

      expect(last_response).to have_status(200)
      expect(Suma::Vendor.all.count).to equal(1)
    end
  end

  describe "GET /v1/vendor/:id" do
    it "returns the vendor" do
      v = Suma::Fixtures.vendor.create
      constraint = Suma::Fixtures.eligibility_constraint.create
      service = Suma::Fixtures.vendor_service.with_constraints(constraint).create(vendor: v)
      product_objs = Array.new(2) { Suma::Fixtures.product.create(vendor: v) }

      get "/v1/vendors/#{v.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        id: v.id,
        services: contain_exactly(
          include(
            id: service.id,
            eligibility_constraints: contain_exactly(include(id: constraint.id)),
          ),
        ),
        products: have_same_ids_as(*product_objs),
      )
    end

    it "403s if the item does not exist" do
      get "/v1/vendors/0"

      expect(last_response).to have_status(403)
    end
  end
end
