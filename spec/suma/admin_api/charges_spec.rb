# frozen_string_literal: true

require "suma/admin_api/charges"
require "suma/api/behaviors"

RSpec.describe Suma::AdminAPI::Charges, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create }

  before(:each) do
    login_as(admin)
  end

  describe "GET /v1/charges" do
    it "returns all charges" do
      c = Array.new(2) { Suma::Fixtures.charge.create }

      get "/v1/charges"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(items: have_same_ids_as(*c))
    end

    it_behaves_like "an endpoint capable of search" do
      let(:url) { "/v1/charges" }
      let(:search_term) { "abcd" }

      def make_matching_items
        return [Suma::Fixtures.charge(opaque_id: "abcdefg").create]
      end

      def make_non_matching_items
        return [Suma::Fixtures.charge(opaque_id: "wibble wobble").create]
      end
    end

    it_behaves_like "an endpoint with pagination" do
      let(:url) { "/v1/charges" }
      def make_item(i)
        # Sorting is newest first, so the first items we create need to the the oldest.
        created = Time.now - i.days
        return Suma::Fixtures.charge.create(created_at: created)
      end
    end

    it_behaves_like "an endpoint with member-supplied ordering" do
      let(:url) { "/v1/charges" }
      let(:order_by_field) { "opaque_id" }
      def make_item(i)
        return Suma::Fixtures.charge.create(
          created_at: Time.now + rand(1..100).days,
          opaque_id: i.to_s,
        )
      end
    end
  end

  describe "GET /v1/charges/:id" do
    it "returns the charge" do
      c = Suma::Fixtures.charge.create

      get "/v1/charges/#{c.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: c.id)
    end

    it "403s if the item does not exist" do
      get "/v1/charges/0"

      expect(last_response).to have_status(403)
    end
  end
end
