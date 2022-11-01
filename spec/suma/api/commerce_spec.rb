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
      offering1 = Suma::Fixtures.commerce_offering.closed.create
      offering2 = Suma::Fixtures.commerce_offering.create
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

  describe "GET /v1/commerce/offerings/:offering_id/products/" do
    it "returns only available offering products" do
      offering = Suma::Fixtures.commerce_offering.create
      product = Suma::Fixtures.commerce_product.create
      op1 = Suma::Fixtures.commerce_offering_product.create(offering:, product:)
      op2 = Suma::Fixtures.commerce_offering_product.closed.create(offering:, product:)
      Suma::Commerce::OfferingProduct.available_with(offering.id)

      get "/v1/commerce/offerings/#{offering.id}/products"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        items: contain_exactly(
          include(id: op1.id),
        ),
      )
    end
  end

  describe "GET /v1/commerce/offerings/:offering_id/products/:product_id" do
    it "returns one offering product" do
      offering = Suma::Fixtures.commerce_offering.create
      product = Suma::Fixtures.commerce_product.create
      Suma::Fixtures.commerce_offering_product.create(offering:, product:)

      get "/v1/commerce/offerings/#{offering.id}/products/#{product.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: product.id, name: product.name)
    end
  end
end
