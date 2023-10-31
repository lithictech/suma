# frozen_string_literal: true

require "suma/admin_api/vendors"

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
  end

  describe "POST /v1/vendors/create" do
    it "creates a vendor" do
      post "/v1/vendors/create", name: "test"
      expect(last_response).to have_status(200)
      expect(Suma::Vendor.all.count).to equal(1)
    end

    it "403s if vendor exists" do
      v = Suma::Fixtures.vendor.create(name: "test")
      post "/v1/vendors/create", name: v.name
      expect(last_response).to have_status(403)
    end
  end

  describe "GET /v1/commerce_offerings/:id" do
    it "returns the vendor" do
      v = Suma::Fixtures.vendor.create
      constraint = Suma::Fixtures.eligibility_constraint.create
      service = Suma::Fixtures.vendor_service.with_constraints(constraint).create(vendor: v)
      product_objs = Array.new(2) { Suma::Fixtures.product.create(vendor: v) }

      get "/v1/vendors/#{v.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        id: v.id,
        payment_account: be_present,
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
