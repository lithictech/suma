# frozen_string_literal: true

require "suma/admin_api/book_transactions"
require "suma/api/behaviors"

RSpec.describe Suma::AdminAPI::BookTransactions, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create }

  before(:each) do
    login_as_admin(admin)
  end

  describe "GET /v1/book_transactions" do
    it "returns all transactions" do
      u = Array.new(2) { Suma::Fixtures.book_transaction.create }

      get "/v1/book_transactions"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(items: have_same_ids_as(*u))
    end

    it_behaves_like "an endpoint capable of search" do
      let(:url) { "/v1/book_transactions" }
      let(:search_term) { "ZIM" }

      def make_matching_items
        return [
          Suma::Fixtures.book_transaction(memo: "zim@zam.zom").create,
          Suma::Fixtures.book_transaction(opaque_id: "Zim Zam").create,
        ]
      end

      def make_non_matching_items
        return [
          Suma::Fixtures.book_transaction(memo: "wibble wobble", opaque_id: "qux@wux").create,
        ]
      end
    end

    it_behaves_like "an endpoint with pagination" do
      let(:url) { "/v1/book_transactions" }
      def make_item(i)
        # Sorting is newest first, so the first items we create need to the the oldest.
        created = Time.now - i.days
        return Suma::Fixtures.book_transaction.create(created_at: created)
      end
    end

    it_behaves_like "an endpoint with member-supplied ordering" do
      let(:url) { "/v1/book_transactions" }
      let(:order_by_field) { "memo" }
      def make_item(i)
        return Suma::Fixtures.book_transaction.create(created_at: Time.now + rand(1..100).days, memo: i.to_s)
      end
    end
  end

  describe "GET /v1/book_transactions/:id" do
    it "returns the transaction" do
      o = Suma::Fixtures.book_transaction.create

      get "/v1/book_transactions/#{o.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: o.id)
    end

    it "403s if the item does not exist" do
      get "/v1/book_transactions/0"

      expect(last_response).to have_status(403)
    end
  end
end
