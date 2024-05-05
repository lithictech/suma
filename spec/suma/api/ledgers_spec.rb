# frozen_string_literal: true

require "suma/api/behaviors"
require "suma/api/ledgers"

RSpec.describe Suma::API::Ledgers, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:member) { Suma::Fixtures.member.with_cash_ledger.create }
  let(:bookfac) { Suma::Fixtures.book_transaction }

  before(:each) do
    login_as(member)
  end

  describe "GET /v1/ledgers/overview" do
    it "always includes cash ledger" do
      get "/v1/ledgers/overview"

      expect(last_response).to have_status(200)
      expect(last_response_json_body).to include(
        ledgers: contain_exactly(
          include(id: member.payment_account.cash_ledger.id, name: "Cash"),
        ),
        first_ledger_page_count: 1,
        first_ledger_lines_first_page: [],
      )
    end

    it "returns an overview of all ledgers and items from the first ledger" do
      cash_led = member.payment_account.cash_ledger
      led2 = Suma::Fixtures.ledger.member(member).create(name: "B")
      recent_xaction = bookfac.from(cash_led).create(apply_at: 20.days.ago, amount_cents: 100)
      old_xaction = bookfac.to(cash_led).create(apply_at: 80.days.ago, amount_cents: 400)
      # Make led2 non-empty
      bookfac.from(led2).create(amount_cents: 200)
      bookfac.to(led2).create(amount_cents: 200)

      get "/v1/ledgers/overview"

      expect(last_response).to have_status(200)
      expect(last_response_json_body).to include(
        ledgers: contain_exactly(
          include(id: cash_led.id, name: "Cash", balance: cost("$3")),
          include(id: led2.id, name: "B", balance: cost("$0")),
        ),
        total_balance: cost("$3"),
        first_ledger_page_count: 1,
        first_ledger_lines_first_page: match(
          [
            include(amount: cost("-$1"), at: match_time(recent_xaction.apply_at)),
            include(amount: cost("$4"), at: match_time(old_xaction.apply_at)),
          ],
        ),
      )
    end

    it "excludes ledgers with no transactions" do
      general_cash = member.payment_account.cash_ledger
      zero_balance = Suma::Fixtures.ledger.member(member).create
      no_xactions = Suma::Fixtures.ledger.member(member).create
      bookfac.from(zero_balance).create(amount_cents: 100)
      bookfac.to(zero_balance).create(amount_cents: 100)

      get "/v1/ledgers/overview"

      expect(last_response).to have_status(200)
      expect(last_response_json_body).to include(
        ledgers: have_same_ids_as(general_cash, zero_balance),
      )
    end
  end

  describe "GET /v1/ledgers/:id/lines" do
    it_behaves_like "an endpoint with pagination" do
      let(:ledger) { Suma::Fixtures.ledger.member(member).create }
      let(:url) { "/v1/ledgers/#{ledger.id}/lines" }
      def make_item(i)
        # Sorting is newest first, so the first items we create need to the the oldest.
        t = Time.now - i.days
        return Suma::Fixtures.book_transaction.from(ledger).create(amount_cents: 100 * (i + 1), apply_at: t)
      end
    end

    it "403s if the ledger does not belong to the member" do
      led = Suma::Fixtures.ledger.create

      get "/v1/ledgers/#{led.id}/lines"

      expect(last_response).to have_status(403)
    end

    it "includes the ledger id" do
      ledger = Suma::Fixtures.ledger.member(member).create

      get "/v1/ledgers/#{ledger.id}/lines"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(ledger_id: ledger.id)
    end
  end
end
