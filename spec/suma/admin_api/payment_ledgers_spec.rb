# frozen_string_literal: true

require "suma/admin_api/payment_ledgers"
require "suma/api/behaviors"

RSpec.describe Suma::AdminAPI::PaymentLedgers, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create }
  let(:platform_account) { Suma::Fixtures.payment_account.create(is_platform_account: true) }

  before(:each) do
    login_as_admin(admin)
  end

  describe "GET /v1/payment_ledgers" do
    it "returns all ledgers with platform ledgers first" do
      non_platform_ledger = Suma::Fixtures.ledger.create
      platform_ledger = Suma::Fixtures.ledger.create(account: platform_account)

      get "/v1/payment_ledgers"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(items: have_same_ids_as(platform_ledger, non_platform_ledger))
    end

    it_behaves_like "an endpoint capable of search" do
      let(:url) { "/v1/payment_ledgers" }
      let(:search_term) { "match" }

      def make_matching_items
        return [
          Suma::Fixtures.ledger(name: "FM match 2023").create,
        ]
      end

      def make_non_matching_items
        return [
          Suma::Fixtures.ledger(name: "wibble wobble").create,
        ]
      end
    end

    it "accepts pagination params, and returns a list object" do
      items = Array.new(5) { |i| Suma::Fixtures.ledger.create(created_at: Time.now - i.days) }

      get "/v1/payment_ledgers", page: 2, per_page: 3

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(
          object: "list",
          items: be_an_instance_of(Array),
          current_page: 1,
          page_count: 1,
          has_more: false,
        )
      expect(last_response_json_body[:items]).to have_same_ids_as(items[3..4])
    end

    it_behaves_like "an endpoint with member-supplied ordering" do
      let(:url) { "/v1/payment_ledgers" }
      let(:order_by_field) { "name" }
      def make_item(i)
        puts i
        return Suma::Fixtures.ledger.create(
          created_at: Time.now + rand(1..100).days,
          name: i.to_s,
        )
      end
    end
  end
  describe "GET /v1/payment_ledgers/:id" do
    it "returns the ledger" do
      ledger = Suma::Fixtures.ledger.member(admin).create
      food_ledger = Suma::Fixtures.ledger.member(admin).create(name: "Food")
      Suma::Fixtures.book_transaction.from(ledger).to(food_ledger).create
      Suma::Fixtures.book_transaction.from(food_ledger).to(ledger).create

      get "/v1/payment_ledgers/#{ledger.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        id: ledger.id,
        combined_book_transactions: have_length(2),
      )
    end

    it "403s if the item does not exist" do
      get "/v1/payment_ledgers/0"

      expect(last_response).to have_status(403)
    end
  end
end
