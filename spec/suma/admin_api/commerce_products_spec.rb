# frozen_string_literal: true

require "suma/admin_api/commerce_products"
require "suma/api/behaviors"

RSpec.describe Suma::AdminAPI::CommerceProducts, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create }

  before(:each) do
    login_as_admin(admin)
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
          # Suma::Fixtures.product(description: translated_text("zim")).create,
        ]
      end

      def make_non_matching_items
        return [
          Suma::Fixtures.product(name: translated_text("wibble wobble")).create,
          # Suma::Fixtures.product(description: translated_text("wibble wobble")).create,
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
end
