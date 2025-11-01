# frozen_string_literal: true

require "suma/api/behaviors"
require "suma/api/ledgers"

RSpec.describe Suma::API::Ledgers, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:member) { Suma::Fixtures.member.create }
  let(:bookfac) { Suma::Fixtures.book_transaction }

  before(:each) do
    login_as(member)
  end

  describe "GET /v1/ledgers/overview" do
    it "handles no ledgers" do
      get "/v1/ledgers/overview"

      expect(last_response).to have_status(200)
      expect(last_response_json_body).to include(
        ledgers: [],
        total_balance: cost("$0"),
        lifetime_savings: cost("$0"),
        recent_lines: [],
      )
    end

    it "always includes cash ledger when it exists" do
      led = Suma::Payment.ensure_cash_ledger(member)

      get "/v1/ledgers/overview"

      expect(last_response).to have_status(200)
      expect(last_response_json_body).to include(
        ledgers: contain_exactly(include(id: led.id, name: "Cash")),
        recent_lines: [],
      )
    end

    it "returns an overview of all ledgers, recent transactions and total balances" do
      led1 = Suma::Fixtures.ledger.member(member).create(name: "A")
      led2 = Suma::Fixtures.ledger.member(member).create(name: "B")
      led1_recent_xaction = bookfac.from(led1).create(apply_at: 20.days.ago, amount_cents: 100)
      led1_old_xaction = bookfac.to(led1).create(apply_at: 80.days.ago, amount_cents: 400)
      charge = Suma::Fixtures.charge(member:).create(undiscounted_subtotal: money("$30"))
      charge.add_line_item(amount: led1_recent_xaction.amount, memo: led1_recent_xaction.memo)
      charge.add_line_item(amount: led1_old_xaction.amount, memo: led1_old_xaction.memo)
      led2_recent_xaction = bookfac.from(led2).create(apply_at: 5.days.ago, amount_cents: 200)
      led2_old_xaction = bookfac.to(led2).create(apply_at: 10.days.ago, amount_cents: 500)

      get "/v1/ledgers/overview"

      expect(last_response).to have_status(200)
      expect(last_response_json_body).to include(
        ledgers: contain_exactly(
          include(id: led1.id, name: "A", balance: cost("$3")),
          include(id: led2.id, name: "B", balance: cost("$3")),
        ),
        total_balance: cost("$6"),
        lifetime_savings: cost("$25"),
        recent_lines: match(
          [
            include(amount: cost("-$2"), at: match_time(led2_recent_xaction.apply_at)),
            include(amount: cost("$5"), at: match_time(led2_old_xaction.apply_at)),
            include(amount: cost("-$1"), at: match_time(led1_recent_xaction.apply_at)),
            include(amount: cost("$4"), at: match_time(led1_old_xaction.apply_at)),
          ],
        ),
      )
    end

    it "excludes ledgers with no transactions" do
      zero_balance = Suma::Fixtures.ledger.member(member).create
      no_xactions = Suma::Fixtures.ledger.member(member).create
      bookfac.from(zero_balance).create(amount_cents: 100)
      bookfac.to(zero_balance).create(amount_cents: 100)

      get "/v1/ledgers/overview"

      expect(last_response).to have_status(200)
      expect(last_response_json_body).to include(
        ledgers: have_same_ids_as(zero_balance),
      )
    end
  end

  describe "GET /v1/ledgers/:id/lines" do
    it_behaves_like "an endpoint with pagination", download: false do
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
