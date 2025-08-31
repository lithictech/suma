# frozen_string_literal: true

require "suma/admin_api/vendor_service_rates"
require "suma/api/behaviors"

RSpec.describe Suma::AdminAPI::VendorServiceRates, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create }

  before(:each) do
    login_as(admin)
  end

  describe "GET /v1/vendor_service_rates" do
    it "returns all objects" do
      objs = Array.new(2) { Suma::Fixtures.vendor_service_rate.create }

      get "/v1/vendor_service_rates"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(items: have_same_ids_as(*objs))
    end

    it_behaves_like "an endpoint with pagination" do
      let(:url) { "/v1/vendor_service_rates" }
      def make_item(i)
        created = Time.now - i.days
        return Suma::Fixtures.vendor_service_rate.create(created_at: created)
      end
    end

    it_behaves_like "an endpoint with member-supplied ordering" do
      let(:url) { "/v1/vendor_service_rates" }
      let(:order_by_field) { "id" }
      def make_item(_i)
        return Suma::Fixtures.vendor_service_rate.create(
          created_at: Time.now + rand(1..100).days,
        )
      end
    end
  end

  describe "POST /v1/vendor_service_rates/create" do
    it "creates a model" do
      rate2 = Suma::Fixtures.vendor_service_rate.create
      post "/v1/vendor_service_rates/create",
           name: "ratename",
           unit_amount: {cents: 7},
           surcharge: {cents: 100},
           unit_offset: 1,
           undiscounted_rate: rate2,
           localization_key: "lockey",
           ordinal: 1

      expect(last_response).to have_status(200)
      expect(Suma::Vendor::ServiceRate.all).to have_length(2)
      expect(last_response).to have_json_body.that_includes(localization_key: "lockey")
    end
  end

  describe "GET /v1/vendor_service_rates/:id" do
    it "returns the object" do
      rate = Suma::Fixtures.vendor_service_rate.create
      pricing = Suma::Fixtures.program_pricing.create(vendor_service_rate: rate)

      get "/v1/vendor_service_rates/#{rate.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        id: rate.id,
        program_pricings: have_same_ids_as(pricing),
      )
    end

    it "403s if the item does not exist" do
      get "/v1/vendor_service_rates/0"

      expect(last_response).to have_status(403)
    end
  end

  describe "POST /v1/vendor_service_rates/:id" do
    it "updates the model" do
      v = Suma::Fixtures.vendor_service_rate.create

      post "/v1/vendor_service_rates/#{v.id}", name: "foo"

      expect(last_response).to have_status(200)
      expect(v.refresh).to have_attributes(name: "foo")
    end
  end
end
