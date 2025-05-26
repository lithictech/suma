# frozen_string_literal: true

require "suma/admin_api/marketing_sms_dispatches"
require "suma/api/behaviors"

RSpec.describe Suma::AdminAPI::MarketingSmsDispatches, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create }

  before(:each) do
    login_as(admin)
  end

  describe "GET /v1/marketing_sms_dispatches" do
    it "returns all objects" do
      u = Array.new(2) { Suma::Fixtures.marketing_sms_dispatch.create }

      get "/v1/marketing_sms_dispatches"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(items: have_same_ids_as(*u))
    end

    it_behaves_like "an endpoint capable of search" do
      let(:url) { "/v1/marketing_sms_dispatches" }
      let(:search_term) { "ZIM" }

      def make_matching_items
        return [
          Suma::Fixtures.marketing_sms_dispatch.to(name: "zim zam zom").create,
        ]
      end

      def make_non_matching_items
        return [
          Suma::Fixtures.marketing_sms_dispatch.to(name: "wibble wobble").create,
        ]
      end
    end

    it_behaves_like "an endpoint with pagination" do
      let(:url) { "/v1/marketing_sms_dispatches" }
      def make_item(i)
        # Sorting is newest first, so the first items we create need to the oldest.
        created = Time.now - i.days
        return Suma::Fixtures.marketing_sms_dispatch.create(created_at: created)
      end
    end

    it_behaves_like "an endpoint with member-supplied ordering" do
      let(:url) { "/v1/marketing_sms_dispatches" }
      let(:order_by_field) { "sent_at" }
      def make_item(i)
        return Suma::Fixtures.marketing_sms_dispatch.create(sent_at: Time.at(i))
      end
    end
  end

  describe "GET /v1/marketing_sms_dispatches/:id" do
    it "returns the object" do
      o = Suma::Fixtures.marketing_sms_dispatch.create

      get "/v1/marketing_sms_dispatches/#{o.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: o.id)
    end

    it "403s if the item does not exist" do
      get "/v1/marketing_sms_dispatches/0"

      expect(last_response).to have_status(403)
    end
  end
end
