# frozen_string_literal: true

require "suma/admin_api/vendor_service_categories"
require "suma/api/behaviors"

RSpec.describe Suma::AdminAPI::VendorServiceCategories, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create }

  before(:each) do
    login_as(admin)
  end

  describe "GET /v1/vendor_service_categories" do
    it "returns all objects" do
      objs = Array.new(2) { Suma::Fixtures.vendor_service_category.create }

      get "/v1/vendor_service_categories"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(items: have_same_ids_as(*objs))
    end

    it_behaves_like "an endpoint with pagination" do
      let(:url) { "/v1/vendor_service_categories" }
      def make_item(i)
        created = Time.now - i.days
        return Suma::Fixtures.vendor_service_category.create(name: created.to_f.to_s)
      end
    end

    it_behaves_like "an endpoint with member-supplied ordering" do
      let(:url) { "/v1/vendor_service_categories" }
      let(:order_by_field) { "name" }
      def make_item(_i)
        return Suma::Fixtures.vendor_service_category.create(name: Time.now.to_f.to_s)
      end
    end
  end

  describe "POST /v1/vendor_service_categories/create" do
    it "creates a model" do
      parent = Suma::Fixtures.vendor_service_category.create
      post("/v1/vendor_service_categories/create", name: "meow", parent: parent)

      expect(last_response).to have_status(200)
      expect(Suma::Vendor::ServiceCategory.all).to have_length(2)
      expect(last_response).to have_json_body.that_includes(name: "meow", parent: include(id: parent.id))
    end
  end

  describe "GET /v1/vendor_service_categories/:id" do
    it "returns the object" do
      rate = Suma::Fixtures.vendor_service_category.create

      get "/v1/vendor_service_categories/#{rate.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: rate.id)
    end

    it "403s if the item does not exist" do
      get "/v1/vendor_service_categories/0"

      expect(last_response).to have_status(403)
    end
  end

  describe "POST /v1/vendor_service_categories/:id" do
    it "updates the model" do
      v = Suma::Fixtures.vendor_service_category.create

      post "/v1/vendor_service_categories/#{v.id}", name: "foo"

      expect(last_response).to have_status(200)
      expect(v.refresh).to have_attributes(name: "foo")
    end
  end
end
