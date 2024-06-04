# frozen_string_literal: true

require "suma/admin_api/commerce_orders"
require "suma/api/behaviors"

RSpec.describe Suma::AdminAPI::CommerceOrders, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create }

  before(:each) do
    login_as(admin)
  end

  describe "GET /v1/commerce_orders" do
    it "returns all orders" do
      objs = Array.new(2) { Suma::Fixtures.order.create }

      get "/v1/commerce_orders"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(items: have_same_ids_as(*objs))
    end

    it_behaves_like "an endpoint with pagination" do
      let(:url) { "/v1/commerce_orders" }
      def make_item(i)
        # Sorting is newest first, so the first items we create need to the the oldest.
        created = Time.now - i.days
        return Suma::Fixtures.order.create(created_at: created)
      end
    end

    it_behaves_like "an endpoint with member-supplied ordering" do
      let(:url) { "/v1/commerce_orders" }
      let(:order_by_field) { "id" }
      def make_item(_i)
        return Suma::Fixtures.order.create(
          created_at: Time.now + rand(1..100).days,
        )
      end
    end
  end

  describe "GET /v1/commerce_orders/:id" do
    it "returns the order" do
      o = Suma::Fixtures.order.as_purchased_by(admin).create

      get "/v1/commerce_orders/#{o.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        id: o.id,
        items: have_length(1),
      )
    end

    it "403s if the item does not exist" do
      get "/v1/commerce_orders/0"

      expect(last_response).to have_status(403)
    end
  end
end
