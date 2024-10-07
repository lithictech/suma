# frozen_string_literal: true

require "suma/admin_api/payout_transactions"
require "suma/api/behaviors"

RSpec.describe Suma::AdminAPI::PayoutTransactions, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create }

  before(:each) do
    login_as(admin)
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

  describe "GET /v1/payout_transactions/stripe_refund" do
    let(:stripe_charge_id) { "ch_1" }
    let(:funding_strategy) do
      Suma::Payment::FundingTransaction::StripeCardStrategy.create(
        originating_card: Suma::Fixtures.card.create,
        charge_json: {id: stripe_charge_id}.to_json,
      )
    end
    let(:amount) { {cents: 500, currency: "USD"} }

    it "using a stripe charge creates the payout and book transaction to the instrument owner cash ledger" do
      member = Suma::Fixtures.member.create
      Suma::Fixtures.funding_transaction.create(
        stripe_card_strategy: funding_strategy,
        originating_payment_account: Suma::Fixtures.payment_account.create(member:),
      )

      Suma::Payment::PayoutTransaction.force_fake(Suma::Payment::FakeStrategy.create.not_ready) do
        post "/v1/payout_transactions/stripe_refund", amount:, stripe_charge_id:
      end

      expect(last_response).to have_status(200)
      expect(last_response.headers).to include("Created-Resource-Admin")
      expect(member.payment_account.originated_payout_transactions).to contain_exactly(
        have_attributes(status: "created", originated_book_transaction: be_present),
      )
    end

    it "409s if the instrument is not usable" do
      Suma::Fixtures.funding_transaction.create(stripe_card_strategy: funding_strategy)

      Suma::Payment::PayoutTransaction.force_fake(Suma::Payment::FakeStrategy.create.invalid) do
        post "/v1/payout_transactions/stripe_refund", amount:, stripe_charge_id:
      end
      expect(last_response).to have_status(409)
    end

    it "403s if funding strategy does not exist with a invalid stripe charge" do
      post "/v1/payout_transactions/stripe_refund", amount:, stripe_charge_id: "ch_invalid"
    end

    it "403s without role access" do
      replace_roles(admin, Suma::Role.cache.noop_admin)

      post "/v1/payout_transactions/stripe_refund", amount: {cents: 500, currency: "USD"}, stripe_charge_id: "ch_1"

      expect(last_response).to have_status(403)
      expect(last_response).to have_json_body.that_includes(error: include(code: "role_check"))
    end
  end
end
