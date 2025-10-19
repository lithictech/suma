# frozen_string_literal: true

require "suma/admin_api/cards"
require "suma/api/behaviors"

RSpec.describe Suma::AdminAPI::Cards, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create }

  before(:each) do
    login_as(admin)
  end

  describe "GET /v1/cards" do
    it "returns all cards" do
      c = Array.new(2) { Suma::Fixtures.card.create }

      get "/v1/cards"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(items: have_same_ids_as(*c))
    end

    it_behaves_like "an endpoint capable of search" do
      let(:url) { "/v1/cards" }
      let(:search_term) { "zzz" }

      def make_matching_items
        return [Suma::Fixtures.card(legal_entity: Suma::Fixtures.legal_entity(name: "zzz").create).create]
      end

      def make_non_matching_items
        return [Suma::Fixtures.card(legal_entity: Suma::Fixtures.legal_entity(name: "wibble wobble").create).create]
      end
    end

    it_behaves_like "an endpoint with pagination" do
      let(:url) { "/v1/cards" }
      def make_item(i)
        # Sorting is newest first, so the first items we create need to the the oldest.
        created = Time.now - i.days
        return Suma::Fixtures.card.create(created_at: created)
      end
    end
  end

  describe "GET /v1/cards/:id" do
    it "returns the item" do
      c = Suma::Fixtures.card.create

      get "/v1/cards/#{c.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: c.id)
    end

    it "403s if the item does not exist" do
      get "/v1/cards/0"

      expect(last_response).to have_status(403)
    end
  end
end
