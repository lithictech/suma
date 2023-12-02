# frozen_string_literal: true

require "suma/admin_api/commerce_offering_fulfillment_options"
require "suma/api/behaviors"

RSpec.describe Suma::AdminAPI::CommerceOfferingFulfillmentOptions, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create }

  before(:each) do
    login_as_admin(admin)
  end

  describe "GET /v1/commerce_offering_fulfillment_options" do
    it "returns all items" do
      objs = Array.new(2) { Suma::Fixtures.offering_fulfillment_option.create }

      get "/v1/commerce_offering_fulfillment_options"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(items: have_same_ids_as(*objs))
    end

    it_behaves_like "an endpoint capable of search" do
      let(:url) { "/v1/commerce_offering_fulfillment_options" }
      let(:search_term) { "ZIM" }

      def make_matching_items
        return [
          Suma::Fixtures.offering_fulfillment_option(description: translated_text("zim")).create,
          Suma::Fixtures.offering_fulfillment_option(description: translated_text("ZIM zam")).create,
        ]
      end

      def make_non_matching_items
        return [
          Suma::Fixtures.offering_fulfillment_option(description: translated_text("wibble wobble")).create,
        ]
      end
    end

    it_behaves_like "an endpoint with pagination" do
      let(:url) { "/v1/commerce_offering_fulfillment_options" }
      def make_item(i)
        # Sorting is newest first, so the first items we create need to the the oldest.
        created = Time.now - i.days
        return Suma::Fixtures.offering_fulfillment_option.create(created_at: created)
      end
    end

    it_behaves_like "an endpoint with member-supplied ordering" do
      let(:url) { "/v1/commerce_offering_fulfillment_options" }
      let(:order_by_field) { "id" }
      def make_item(_i)
        return Suma::Fixtures.offering_fulfillment_option.create(
          created_at: Time.now + rand(1..100).days,
        )
      end
    end
  end

  describe "POST /v1/commerce_offering_fulfillment_options/create" do
    it "creates the item" do
      o = Suma::Fixtures.offering.create

      post "/v1/commerce_offering_fulfillment_options/create",
           offering: {id: o.id},
           description: {en: "EN test", es: "ES test"},
           type: "pickup",
           ordinal: 1

      expect(last_response).to have_status(200)
      expect(last_response.headers).to include("Created-Resource-Admin")
      expect(o.refresh.fulfillment_options).to have_length(1)
      expect(o.fulfillment_options.first).to have_attributes(
        description: have_attributes(en: "EN test"),
      )
    end
  end

  describe "GET /v1/commerce_offering_fulfillment_options/:id" do
    it "returns the item" do
      o = Suma::Fixtures.offering_fulfillment_option.create

      get "/v1/commerce_offering_fulfillment_options/#{o.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: o.id)
    end

    it "403s if the item does not exist" do
      get "/v1/commerce_offering_fulfillment_options/0"

      expect(last_response).to have_status(403)
    end
  end

  describe "POST /v1/commerce_offering_fulfillment_options/:id" do
    it "updates the model" do
      o = Suma::Fixtures.offering_fulfillment_option.create
      post "/v1/commerce_offering_fulfillment_options/#{o.id}",
           description: {en: "EN test", es: "ES test"}

      expect(last_response).to have_status(200)
      expect(o.refresh).to have_attributes(description: have_attributes(en: "EN test"))
    end

    it "can set the address" do
      o = Suma::Fixtures.offering_fulfillment_option.create
      a = Suma::Fixtures.address.create(address1: "123 Main", postal_code: "12345")
      post "/v1/commerce_offering_fulfillment_options/#{o.id}",
           type: "delivery",
           address: {address1: "123 Main", city: "Portland", state_or_province: "OR", postal_code: "12345"}

      expect(last_response).to have_status(200)
      expect(o.refresh).to have_attributes(address: be === a)
    end
  end
end
