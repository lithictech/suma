# frozen_string_literal: true

require "suma/admin_api/marketing_lists"
require "suma/api/behaviors"

RSpec.describe Suma::AdminAPI::MarketingLists, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create }

  before(:each) do
    login_as(admin)
  end

  describe "GET /v1/marketing_lists" do
    it "returns all objects" do
      u = Array.new(2) { Suma::Fixtures.marketing_list.create }

      get "/v1/marketing_lists"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(items: have_same_ids_as(*u))
    end

    it_behaves_like "an endpoint capable of search" do
      let(:url) { "/v1/marketing_lists" }
      let(:search_term) { "ZIM" }

      def make_matching_items
        return [
          Suma::Fixtures.marketing_list(label: "zim zam zom").create,
        ]
      end

      def make_non_matching_items
        return [
          Suma::Fixtures.marketing_list(label: "wibble wobble").create,
        ]
      end
    end

    it_behaves_like "an endpoint with pagination" do
      let(:url) { "/v1/marketing_lists" }
      def make_item(i)
        # Sorting is newest first, so the first items we create need to the oldest.
        created = Time.now - i.days
        return Suma::Fixtures.marketing_list.create(created_at: created)
      end
    end

    it_behaves_like "an endpoint with member-supplied ordering" do
      let(:url) { "/v1/marketing_lists" }
      let(:order_by_field) { "label" }
      def make_item(i)
        return Suma::Fixtures.marketing_list.create(label: i.to_s)
      end
    end
  end

  describe "GET /v1/marketing_lists/:id" do
    it "returns the object" do
      o = Suma::Fixtures.marketing_list.create

      get "/v1/marketing_lists/#{o.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: o.id)
    end

    it "403s if the item does not exist" do
      get "/v1/marketing_lists/0"

      expect(last_response).to have_status(403)
    end
  end
end
