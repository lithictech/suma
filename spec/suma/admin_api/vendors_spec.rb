# frozen_string_literal: true

require "suma/admin_api/vendors"
require "suma/api/behaviors"

RSpec.describe Suma::AdminAPI::Vendors, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create }
  let(:photo_file) { File.open("spec/data/images/photo.png", "rb") }
  let(:image) { Rack::Test::UploadedFile.new(photo_file, "image/png", true) }

  before(:each) do
    login_as(admin)
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
      let(:search_term) { "johns farm" }

      def make_matching_items
        return [
          Suma::Fixtures.vendor(name: "Johns Farmers Market").create,
        ]
      end

      def make_non_matching_items
        return [
          Suma::Fixtures.vendor(name: "wibble wobble").create,
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
      post("/v1/vendors/create", name: "test", image:)

      expect(last_response).to have_status(200)
      expect(Suma::Vendor.all).to have_length(1)
    end
  end

  describe "GET /v1/vendor/:id" do
    it "returns the vendor" do
      v = Suma::Fixtures.vendor.create
      service = Suma::Fixtures.vendor_service.create(vendor: v)
      product_objs = Array.new(2) { Suma::Fixtures.product.create(vendor: v) }

      get "/v1/vendors/#{v.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        id: v.id,
        services: have_same_ids_as(service),
        products: have_same_ids_as(*product_objs),
      )
    end

    it "403s if the item does not exist" do
      get "/v1/vendors/0"

      expect(last_response).to have_status(403)
    end
  end

  describe "POST /v1/vendors/:id" do
    it "updates a vendor" do
      v = Suma::Fixtures.vendor.create

      post("/v1/vendors/#{v.id}", name: "test", image:)

      expect(last_response).to have_status(200)
      expect(v.refresh).to have_attributes(name: "test")
    end
  end

  describe "POST /v1/vendors/:id/destroy" do
    it "destroys a vendor" do
      v = Suma::Fixtures.vendor.create
      # Need to destroy this for the destroy to work. Probably shouldn't create this automatically.
      v.payment_account.destroy

      post "/v1/vendors/#{v.id}/destroy"

      expect(last_response).to have_status(200)
      expect(v).to be_destroyed
    end
  end
end
