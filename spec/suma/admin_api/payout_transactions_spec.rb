# frozen_string_literal: true

require "suma/admin_api/payout_transactions"
require "suma/api/behaviors"

RSpec.describe Suma::AdminAPI::PayoutTransactions, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create }

  before(:each) do
    login_as_admin(admin)
  end

  describe "GET /v1/payout_transactions" do
    it "returns all transactions" do
      u = Array.new(2) { Suma::Fixtures.payout_transaction.with_fake_strategy.create }

      get "/v1/payout_transactions"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(items: have_same_ids_as(*u))
    end

    it_behaves_like "an endpoint capable of search" do
      let(:url) { "/v1/payout_transactions" }
      let(:search_term) { "ZIM" }

      def make_matching_items
        return [
          Suma::Fixtures.payout_transaction(memo: translated_text("zim@zam.zom")).with_fake_strategy.create,
        ]
      end

      def make_non_matching_items
        return [
          Suma::Fixtures.payout_transaction(memo: translated_text("wibble wobble")).with_fake_strategy.create,
        ]
      end
    end

    it_behaves_like "an endpoint with pagination" do
      let(:url) { "/v1/payout_transactions" }
      def make_item(i)
        # Sorting is newest first, so the first items we create need to the the oldest.
        created = Time.now - i.days
        return Suma::Fixtures.payout_transaction.with_fake_strategy.create(created_at: created)
      end
    end

    it_behaves_like "an endpoint with member-supplied ordering" do
      let(:url) { "/v1/payout_transactions" }
      let(:order_by_field) { "updated_at" }
      def make_item(i)
        return Suma::Fixtures.payout_transaction.
            with_fake_strategy.
            create(created_at: Time.now + rand(1..100).days, updated_at: i.days.from_now)
      end
    end
  end

  describe "GET /v1/payout_transactions/:id" do
    it "returns the transaction" do
      o = Suma::Fixtures.payout_transaction.with_fake_strategy.create

      get "/v1/payout_transactions/#{o.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: o.id)
    end

    it "403s if the item does not exist" do
      get "/v1/payout_transactions/0"

      expect(last_response).to have_status(403)
    end
  end
end
