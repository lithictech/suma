# frozen_string_literal: true

require "suma/admin_api/commerce_offering_products"
require "suma/api/behaviors"

RSpec.describe Suma::AdminAPI::CommerceOfferingProducts, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create }

  before(:each) do
    login_as(admin)
  end

  describe "POST /v1/commerce_offering_products/create" do
    it "creates the offering product" do
      o = Suma::Fixtures.offering.create
      p = Suma::Fixtures.product.create

      post "/v1/commerce_offering_products/create",
           offering: {id: o.id},
           product: {id: p.id},
           customer_price: {cents: 1900},
           undiscounted_price: {cents: 2400}

      expect(last_response).to have_status(200)
      expect(last_response.headers).to include("Created-Resource-Admin")
      p = Suma::Commerce::OfferingProduct.first
      expect(Suma::Commerce::OfferingProduct.all).to have_length(1)
      expect(p).to have_attributes(customer_price: cost("$19"))
    end
  end

  describe "GET /v1/commerce_offering_products/:id" do
    it "returns the offering product" do
      x = Suma::Fixtures.offering_product.create

      get "/v1/commerce_offering_products/#{x.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: x.id)
    end
  end

  describe "POST /v1/commerce_offering_products/:id" do
    it "creates and returns a modified offering product" do
      op = Suma::Fixtures.offering_product.costing("$1", "$2").create

      post "/v1/commerce_offering_products/#{op.id}",
           customer_price: {cents: 1900},
           undiscounted_price: {cents: 2400}

      expect(last_response).to have_status(200)
      expect(last_response.headers).to include("Created-Resource-Admin")
      expect(last_response).to have_json_body.that_includes(id: be > op.id)
      expect(op.refresh).to have_attributes(customer_price: cost("$1"), closed?: true)
      expect(Suma::Commerce::OfferingProduct.order(:id).last).to have_attributes(
        customer_price: cost("$19"), undiscounted_price: cost("$24"),
      )
    end
  end
end
