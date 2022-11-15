# frozen_string_literal: true

require "suma/admin_api/funding_transactions"
require "suma/api/behaviors"

RSpec.describe Suma::AdminAPI::FundingTransactions, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create }

  before(:each) do
    login_as_admin(admin)
  end

  describe "GET /v1/funding_transactions" do
    it "returns all transactions" do
      u = Array.new(2) { Suma::Fixtures.funding_transaction.with_fake_strategy.create }

      get "/v1/funding_transactions"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(items: have_same_ids_as(*u))
    end

    it_behaves_like "an endpoint capable of search" do
      let(:url) { "/v1/funding_transactions" }
      let(:search_term) { "ZIM" }

      def make_matching_items
        return [
          Suma::Fixtures.funding_transaction(memo: "zim@zam.zom").with_fake_strategy.create,
        ]
      end

      def make_non_matching_items
        return [
          Suma::Fixtures.funding_transaction(memo: "wibble wobble").with_fake_strategy.create,
        ]
      end
    end

    it_behaves_like "an endpoint with pagination" do
      let(:url) { "/v1/funding_transactions" }
      def make_item(i)
        # Sorting is newest first, so the first items we create need to the the oldest.
        created = Time.now - i.days
        return Suma::Fixtures.funding_transaction.with_fake_strategy.create(created_at: created)
      end
    end

    it_behaves_like "an endpoint with member-supplied ordering" do
      let(:url) { "/v1/funding_transactions" }
      let(:order_by_field) { "memo" }
      def make_item(i)
        return Suma::Fixtures.funding_transaction.
            with_fake_strategy.
            create(created_at: Time.now + rand(1..100).days, memo: i.to_s)
      end
    end
  end

  describe "GET /v1/funding_transactions/:id" do
    it "returns the transaction" do
      o = Suma::Fixtures.funding_transaction.with_fake_strategy.create

      get "/v1/funding_transactions/#{o.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: o.id)
    end

    it "403s if the item does not exist" do
      get "/v1/funding_transactions/0"

      expect(last_response).to have_status(403)
    end
  end

  describe "POST /v1/funding_transactions/create_for_self" do
    it "creates the funding and book transaction to the instrument owner cash ledger" do
      member = Suma::Fixtures.member.create
      ba = Suma::Fixtures.bank_account.member(member).verified.create

      Suma::Payment::FundingTransaction.force_fake(Suma::Payment::FakeStrategy.create.not_ready) do
        post "/v1/funding_transactions/create_for_self",
             amount: {cents: 500, currency: "USD"},
             payment_instrument_id: ba.id,
             payment_method_type: ba.payment_method_type
      end

      expect(last_response).to have_status(200)
      expect(last_response.headers).to include("Created-Resource-Admin")
      expect(member.payment_account.originated_funding_transactions).to contain_exactly(
        have_attributes(status: "created", originated_book_transaction: be_present),
      )
    end
  end
end
