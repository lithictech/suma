# frozen_string_literal: true

require "suma/admin_api/anon_proxy"
require "suma/admin_api/common_endpoints"
require "suma/admin_api/vendors"
require "suma/api/behaviors"

RSpec.describe Suma::AdminAPI::CommonEndpoints, :db do
  include Rack::Test::Methods

  let(:app) { Suma::AdminAPI::Vendors.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create }
  let(:photo_file) { File.open("spec/data/images/photo.png", "rb") }
  let(:image) { Rack::Test::UploadedFile.new(photo_file, "image/png", true) }

  before(:each) do
    login_as(admin)
  end

  def replace_admin_role(r)
    admin.remove_role(Suma::Role.cache.admin)
    admin.add_role(r) if r
  end

  describe "list" do
    it "returns all resources" do
      objs = Array.new(2) { Suma::Fixtures.vendor.create }

      get "/v1/vendors"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(items: have_same_ids_as(*objs))
    end

    it "401s if the user does not have admin access" do
      replace_admin_role(nil)

      get "/v1/vendors"

      expect(last_response).to have_status(401)
    end

    it "403s if the user cannot read the resource" do
      replace_admin_role(Suma::Role.cache.noop_admin)

      get "/v1/vendors"

      expect(last_response).to have_status(403)
      expect(last_response).to have_json_body.that_includes(error: include(code: "role_check"))
    end

    it "can specify a custom ordering along with search", :hybrid_search do
      geralt = Suma::Fixtures.vendor.create(name: "Geralt of Rivia")
      ciri = Suma::Fixtures.vendor.create(name: "Ciri of Rivia")
      yen = Suma::Fixtures.vendor.create(name: "Yennefer of Vengerburg")
      Suma::Vendor.hybrid_search_reindex_all

      get "/v1/vendors", search: "Rivia"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(items: have_same_ids_as(geralt, ciri).ordered)

      get "/v1/vendors", search: "Rivia", order_by: "name", order_direction: "asc"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(items: have_same_ids_as(ciri, geralt).ordered)
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

  describe "create" do
    it "creates a resource" do
      post("/v1/vendors/create", name: "test", image:)

      expect(last_response).to have_status(200)
      expect(Suma::Vendor.all).to have_length(1)
    end

    it "403s if the user does not have admin access" do
      replace_admin_role(nil)

      post("/v1/vendors/create", name: "test", image:)

      expect(last_response).to have_status(401)
    end

    it "403s if the user cannot write the resource" do
      replace_admin_role(Suma::Role.cache.readonly_admin)

      post("/v1/vendors/create", name: "test", image:)

      expect(last_response).to have_status(403)
      expect(last_response).to have_json_body.that_includes(error: include(code: "role_check"))
    end
  end

  describe "get_one" do
    it "returns the resource" do
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

    it "403s if the resource does not exist" do
      get "/v1/vendors/0"

      expect(last_response).to have_status(403)
    end

    it "401s if the user does not have admin access" do
      replace_admin_role(nil)

      v = Suma::Fixtures.vendor.create
      get "/v1/vendors/#{v.id}"

      expect(last_response).to have_status(401)
    end

    it "403s if the user cannot read the resource" do
      replace_admin_role(Suma::Role.cache.noop_admin)

      v = Suma::Fixtures.vendor.create
      get "/v1/vendors/#{v.id}"

      expect(last_response).to have_status(403)
      expect(last_response).to have_json_body.that_includes(error: include(code: "role_check"))
    end
  end

  describe "update" do
    it "updates a resource" do
      v = Suma::Fixtures.vendor.create

      post("/v1/vendors/#{v.id}", name: "test", image:)

      expect(last_response).to have_status(200)
      expect(v.refresh).to have_attributes(name: "test")
    end

    it "replaces an existing image" do
      v = Suma::Fixtures.vendor.create
      old_image = Suma::Fixtures.image.for(v).create

      post("/v1/vendors/#{v.id}", image:)

      expect(last_response).to have_status(200)
      expect(v.refresh.images).to have_length(1)
      expect(v.images.first).to have_attributes(id: be > old_image.id)
    end

    it "403s if the resource does not exist" do
      post "/v1/vendors/0"

      expect(last_response).to have_status(403)
    end

    it "403s if the user does not have admin access" do
      replace_admin_role(nil)

      v = Suma::Fixtures.vendor.create
      post("/v1/vendors/#{v.id}", name: "test")

      expect(last_response).to have_status(401)
    end

    it "403s if the user cannot write the resource" do
      replace_admin_role(Suma::Role.cache.readonly_admin)

      v = Suma::Fixtures.vendor.create
      post("/v1/vendors/#{v.id}", name: "test")

      expect(last_response).to have_status(403)
      expect(last_response).to have_json_body.that_includes(error: include(code: "role_check"))
    end
  end

  describe "destroy" do
    it "destroys and returns the resource" do
      v = Suma::Fixtures.vendor.create
      # Need to destroy this for the destroy to work. Probably shouldn't create this automatically.
      v.payment_account.destroy

      post "/v1/vendors/#{v.id}/destroy"

      expect(last_response).to have_status(200)
      expect(v).to be_destroyed
    end

    it "403s if the resource does not exist" do
      post "/v1/vendors/0/destroy"

      expect(last_response).to have_status(403)
    end

    it "401s if the user does not have admin access" do
      replace_admin_role(nil)

      r = Suma::Fixtures.vendor.create
      post "/v1/vendors/#{r.id}/destroy"

      expect(last_response).to have_status(401)
    end

    it "403s if the user cannot read the resource" do
      replace_admin_role(Suma::Role.cache.noop_admin)

      r = Suma::Fixtures.vendor.create
      post "/v1/vendors/#{r.id}/destroy"

      expect(last_response).to have_status(403)
      expect(last_response).to have_json_body.that_includes(error: include(code: "role_check"))
    end
  end
end
