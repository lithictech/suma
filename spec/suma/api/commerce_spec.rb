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

      get "/v1/commerce/offerings"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        items: contain_exactly(
          include(id: offering2.id),
        ),
      )
    end

    it "401s if not authed" do
      logout
      get "/v1/commerce/offerings"
      expect(last_response).to have_status(401)
    end
  end

  describe "GET /v1/commerce/offerings/:offering_id" do
    it "returns details about the offering and the member cart" do
      offering = Suma::Fixtures.offering.create
      product = Suma::Fixtures.product.create
      cart = Suma::Fixtures.cart(offering:, member:).with_product(product).create

      get "/v1/commerce/offerings/#{offering.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        id: offering.id,
        description: offering.description.en,
        cart: include(
          items: contain_exactly(include(product_id: product.id)),
        ),
      )
    end

    it "returns a blank cart if one does not exist" do
      offering = Suma::Fixtures.offering.create

      get "/v1/commerce/offerings/#{offering.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(cart: include(items: []))
    end

    it "can handle cart items without offering products" do
      offering = Suma::Fixtures.offering.create
      product = Suma::Fixtures.product.create
      cart = Suma::Fixtures.cart(offering:, member:).with_product(product).create

      get "/v1/commerce/offerings/#{offering.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        cart: include(
          items: contain_exactly(
            include(
              product_id: product.id,
              is_discounted: false,
              customer_price: include(cents: 0),
              undiscounted_price: include(cents: 0),
            ),
          ),
        ),
      )
    end

    it "401s if not authed" do
      logout
      offering = Suma::Fixtures.offering.create
      get "/v1/commerce/offerings/#{offering.id}"
      expect(last_response).to have_status(401)
    end
  end

  describe "GET /v1/commerce/offerings/:offering_id/products" do
    it "returns only available offering products" do
      offering = Suma::Fixtures.offering.create
      product = Suma::Fixtures.product.create
      op1 = Suma::Fixtures.offering_product.create(offering:, product:)
      op2 = Suma::Fixtures.offering_product.closed.create(offering:, product:)

      get "/v1/commerce/offerings/#{offering.id}/products"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        items: contain_exactly(
          include(product_id: op1.product_id),
        ),
      )
    end

    it "returns details about the offering and the member cart" do
      offering = Suma::Fixtures.offering.create

      get "/v1/commerce/offerings/#{offering.id}/products"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        offering: include(id: offering.id, description: offering.description.en),
        cart: include(items: []),
      )
    end

    it "401s if not authed" do
      logout
      offering = Suma::Fixtures.offering.create
      get "/v1/commerce/offerings/#{offering.id}/products"
      expect(last_response).to have_status(401)
    end
  end

  describe "GET /v1/commerce/offerings/:offering_id/products/:product_id" do
    let(:offering) { Suma::Fixtures.offering.create }
    let(:product) { Suma::Fixtures.product.create }
    before(:each) do
      Suma::Fixtures.offering_product.create(offering:, product:)
    end
    it "returns one offering product and the member cart for the offering" do
      get "/v1/commerce/offerings/#{offering.id}/products/#{product.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(product_id: product.id, cart: include(items: []))
    end
    it "403s if product does not belong to offering" do
      get "/v1/commerce/offerings/#{offering.id}/products/0"

      expect(last_response).to have_status(403)
    end
    it "403s if offering does not belong to product" do
      get "/v1/commerce/offerings/0/products/#{product.id}"

      expect(last_response).to have_status(403)
    end
    it "401s if not authed" do
      logout
      get "/v1/commerce/offerings/#{offering.id}/products/#{product.id}"
      expect(last_response).to have_status(401)
    end
  end

  describe "PUT /v1/commerce/offerings/:offering_id/cart_item" do
    let(:offering) { Suma::Fixtures.offering.create }
    let(:product) { Suma::Fixtures.product.create }
    let!(:offering_product) { Suma::Fixtures.offering_product.create(offering:, product:) }

    it "adds a product (uses Cart#set_item)" do
      put "/v1/commerce/offerings/#{offering.id}/cart_item", product_id: product.id, quantity: 2

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        id: offering.id,
        cart: include(
          items: contain_exactly(include(product_id: product.id, quantity: 2)),
        ),
      )
    end

    it "ignores the change and returns the existing cart if for out of order updates" do
      cart = Suma::Fixtures.cart(offering:, member:).with_product(product, 10, timestamp: 2).create

      put "/v1/commerce/offerings/#{offering.id}/cart_item", product_id: product.id, quantity: 2, timestamp: 1

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        id: offering.id,
        cart: include(
          items: contain_exactly(include(product_id: product.id, quantity: 10)),
        ),
      )
    end

    it "returns a 409 for product unavailable" do
      offering_product.delete

      put "/v1/commerce/offerings/#{offering.id}/cart_item", product_id: product.id, quantity: 2, timestamp: 1

      expect(last_response).to have_status(409)
      expect(last_response).to have_json_body.
        that_includes(error: include(code: "product_unavailable"))
    end
  end
end
