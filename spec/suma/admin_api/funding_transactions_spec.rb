# frozen_string_literal: true

require "suma/admin_api/funding_transactions"
require "suma/api/behaviors"

RSpec.describe Suma::AdminAPI::FundingTransactions, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create }

  before(:each) do
    login_as(admin)
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
          Suma::Fixtures.funding_transaction(memo: translated_text("zim zam zom")).with_fake_strategy.create,
        ]
      end

      def make_non_matching_items
        return [
          Suma::Fixtures.funding_transaction(memo: translated_text("wibble wobble")).with_fake_strategy.create,
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
      let(:order_by_field) { "updated_at" }
      def make_item(i)
        return Suma::Fixtures.funding_transaction.
            with_fake_strategy.
            create(created_at: Time.now + rand(1..100).days, updated_at: i.days.from_now)
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
    let(:member) { Suma::Fixtures.member.create }

    it "using a bank account creates the funding and book transaction to the instrument owner cash ledger" do
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

    it "using a card creates the funding and book transaction to the instrument owner cash ledger" do
      card = Suma::Fixtures.card.member(member).create

      Suma::Payment::FundingTransaction.force_fake(Suma::Payment::FakeStrategy.create.not_ready) do
        post "/v1/funding_transactions/create_for_self",
             amount: {cents: 500, currency: "USD"},
             payment_instrument_id: card.id,
             payment_method_type: card.payment_method_type
      end

      expect(last_response).to have_status(200)
      expect(last_response.headers).to include("Created-Resource-Admin")
      expect(member.payment_account.originated_funding_transactions).to contain_exactly(
        have_attributes(status: "created", originated_book_transaction: be_present),
      )
    end

    it "errors if the instrument is not usable" do
      card = Suma::Fixtures.card.member(member).create

      Suma::Payment::FundingTransaction.force_fake(Suma::Payment::FakeStrategy.create.invalid) do
        post "/v1/funding_transactions/create_for_self",
             amount: {cents: 500, currency: "USD"},
             payment_instrument_id: card.id,
             payment_method_type: card.payment_method_type
      end

      expect(last_response).to have_status(409)
    end

    it "errors without role access" do
      replace_roles(admin, Suma::Role.cache.noop_admin)

      post "/v1/funding_transactions/create_for_self",
           amount: {cents: 500, currency: "USD"},
           payment_instrument_id: 1,
           payment_method_type: "card"

      expect(last_response).to have_status(403)
      expect(last_response).to have_json_body.that_includes(error: include(code: "role_check"))
    end
  end

  describe "POST /v1/funding_transactions/:id/refund" do
    let(:instrument) { Suma::Fixtures.bank_account.create }
    let(:fx) do
      fx = Suma::Fixtures.funding_transaction.with_fake_strategy.create(amount: money("$10"))
      fx.strategy.set_response(:originating_instrument, instrument)
      fx.strategy.set_response(:check_validity, [])
      fx.strategy.set_response(:ready_to_send_funds?, false)
      fx
    end

    it "refunds the refundable amount amount if :full is passed" do
      Suma::Fixtures::PayoutTransactions.refund_of(fx, Suma::Fixtures.card.create, amount: money("$1"))

      post "/v1/funding_transactions/#{fx.id}/refund", full: true

      expect(last_response).to have_status(200)
      expect(last_response.headers).to include("Created-Resource-Admin")
      px = Suma::Payment::PayoutTransaction.find!(id: last_response.headers["Created-Resource-Id"].to_i)
      expect(px).to have_attributes(amount: cost("$9"))
    end

    it "can refund the specified amount" do
      post "/v1/funding_transactions/#{fx.id}/refund", amount: {cents: 450, currency: "USD"}

      expect(last_response).to have_status(200)
      px = Suma::Payment::PayoutTransaction.where(refunded_funding_transaction: fx).first
      expect(px).to_not be_nil
      expect(px).to have_attributes(amount: cost("$4.50"))
    end

    it "errors if the refund amount is too high" do
      post "/v1/funding_transactions/#{fx.id}/refund", amount: {cents: 1200, currency: "USD"}

      expect(last_response).to have_status(400)
      expect(last_response).to have_json_body.
        that_includes(error: include(message: /Refund cannot be greater/))
    end

    it "errors without role access" do
      replace_roles(admin, Suma::Role.cache.noop_admin)

      post "/v1/funding_transactions/#{fx.id}/refund", full: true

      expect(last_response).to have_status(403)
      expect(last_response).to have_json_body.that_includes(error: include(code: "role_check"))
    end
  end
end
