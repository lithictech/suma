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
end
