# frozen_string_literal: true

require "suma/admin_api/commerce_products"
require "suma/api/behaviors"

RSpec.describe Suma::AdminAPI::CommerceProducts, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create }

  before(:each) do
    login_as(admin)
  end

  describe "GET /v1/commerce_products" do
    it "returns all products" do
      objs = Array.new(2) { Suma::Fixtures.product.create }

      get "/v1/commerce_products"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(items: have_same_ids_as(*objs))
    end

    it_behaves_like "an endpoint capable of search" do
      let(:url) { "/v1/commerce_products" }
      let(:search_term) { "ZIM" }

      def make_matching_items
        return [
          Suma::Fixtures.product(name: translated_text("ZIM zam")).create,
        ]
      end

      def make_non_matching_items
        return [
          Suma::Fixtures.product(name: translated_text("wibble wobble")).create,
        ]
      end
    end

    it_behaves_like "an endpoint with pagination" do
      let(:url) { "/v1/commerce_products" }
      def make_item(i)
        # Sorting is newest first, so the first items we create need to the the oldest.
        created = Time.now - i.days
        return Suma::Fixtures.product.create(created_at: created)
      end
    end

    it_behaves_like "an endpoint with member-supplied ordering" do
      let(:url) { "/v1/commerce_products" }
      let(:order_by_field) { "id" }
      def make_item(_i)
        return Suma::Fixtures.product.create(
          created_at: Time.now + rand(1..100).days,
        )
      end
    end
  end

  describe "POST /v1/commerce_products/create" do
    it "creates the product" do
      photo_file = File.open("spec/data/images/photo.png", "rb")
      image = Rack::Test::UploadedFile.new(photo_file, "image/png", true)
      cat = Suma::Fixtures.vendor_service_category.food.create
      vs = Suma::Fixtures.vendor_service.create

      post "/v1/commerce_products/create",
           image:,
           name: {en: "EN name", es: "ES name"},
           description: {en: "EN description", es: "ES description"},
           our_cost: {cents: 2400},
           # Include 'name' to represent how this comes through on create better.
           # We make sure the name doesn't get set, as it isn't a declared parameter.
           vendor: {id: vs.vendor.id, name: "X"},
           vendor_service_categories: {"0" => {id: cat.id}}

      expect(last_response).to have_status(200)
      expect(last_response.headers).to include("Created-Resource-Admin")
      p = Suma::Commerce::Product.first
      expect(Suma::Commerce::Product.all).to have_length(1)
      expect(p).to have_attributes(our_cost: cost("$24"))
      expect(vs.vendor.refresh).to_not have_attributes(name: "X")
    end
  end

  describe "GET /v1/commerce_products/:id" do
    it "returns the product" do
      x = Suma::Fixtures.product.create

      get "/v1/commerce_products/#{x.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: x.id)
    end

    it "403s if the item does not exist" do
      get "/v1/commerce_products/0"

      expect(last_response).to have_status(403)
    end
  end

  describe "POST /v1/commerce_products/:id" do
    it "updates the product and can create a new inventory" do
      photo_file = File.open("spec/data/images/photo.png", "rb")
      image = Rack::Test::UploadedFile.new(photo_file, "image/png", true)
      product = Suma::Fixtures.product.create

      post "/v1/commerce_products/#{product.id}",
           image:,
           our_cost: {cents: 2400},
           inventory: {quantity_on_hand: 2}

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: product.id)
      expect(product.refresh).to have_attributes(our_cost: cost("$24"))
      expect(product.inventory).to have_attributes(quantity_on_hand: 2)
    end

    it "updates the product and existing inventory" do
      product = Suma::Fixtures.product.create
      product.inventory!.update(quantity_on_hand: 5)

      post "/v1/commerce_products/#{product.id}", inventory: {quantity_on_hand: 201}

      expect(last_response).to have_status(200)
      expect(product.inventory.refresh).to have_attributes(quantity_on_hand: 201)
    end

    it "does not update undeclared params" do
      product = Suma::Fixtures.product.create
      v2 = Suma::Fixtures.vendor.create

      post "/v1/commerce_products/#{product.id}", vendor: {id: v2.id, name: "X"}

      expect(last_response).to have_status(200)
      expect(product.refresh).to have_attributes(vendor: be === v2)
      expect(v2.refresh).to_not have_attributes(name: "X")
    end
  end
end
