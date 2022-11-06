# frozen_string_literal: true

require "suma/api/commerce"

RSpec.describe Suma::API::Commerce, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:member) { Suma::Fixtures.member.create }

  before(:each) do
    login_as(member)
  end

  describe "GET /v1/commerce/offerings" do
    it "returns only available offerings" do
      offering1 = Suma::Fixtures.offering.closed.create
      offering2 = Suma::Fixtures.offering.create
      Suma::Commerce::Offering.available_at(Time.now)

      get "/v1/commerce/offerings"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        items: contain_exactly(
          include(id: offering2.id),
        ),
      )
    end
  end

  describe "GET /v1/commerce/offerings/:offering_id/products" do
    it "returns only available offering products" do
      offering = Suma::Fixtures.offering.create
      product = Suma::Fixtures.product.create
      op1 = Suma::Fixtures.offering_product.create(offering:, product:)
      op2 = Suma::Fixtures.offering_product.closed.create(offering:, product:)
      Suma::Commerce::OfferingProduct.available_with(offering.id)

      get "/v1/commerce/offerings/#{offering.id}/products"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        items: contain_exactly(
          include(product_id: op1.product_id),
        ),
      )
    end

    it "returns details about the offering" do
      offering = Suma::Fixtures.offering.create

      get "/v1/commerce/offerings/#{offering.id}/products"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        offering: include(id: offering.id, description: offering.description.en),
      )
    end
  end

  describe "GET /v1/commerce/offerings/:offering_id/products/:product_id" do
    let(:offering) { Suma::Fixtures.offering.create }
    let(:product) { Suma::Fixtures.product.create }
    before(:each) do
      Suma::Fixtures.offering_product.create(offering:, product:)
    end
    it "returns one offering product" do
      get "/v1/commerce/offerings/#{offering.id}/products/#{product.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(product_id: product.id, offering_id: offering.id)
    end
    it "403s if product does not belong to offering" do
      get "/v1/commerce/offerings/#{offering.id}/products/0"

      expect(last_response).to have_status(403)
    end
    it "403s if offering does not belong to product" do
      get "/v1/commerce/offerings/0/products/#{product.id}"

      expect(last_response).to have_status(403)
    end
  end
end
