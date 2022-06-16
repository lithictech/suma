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
    it "returns an overview of all ledgers" do
      led1 = Suma::Fixtures.ledger.member(member).create(name: "A")
      led2 = Suma::Fixtures.ledger.member(member).create(name: "B")
      recent_xaction = bookfac.from(led1).create(apply_at: 20.days.ago, amount_cents: 100)
      old_xaction = bookfac.to(led1).create(apply_at: 80.days.ago, amount_cents: 400)

      get "/v1/ledgers/overview"

      expect(last_response).to have_status(200)
      expect(last_response_json_body).to include(
        ledgers: contain_exactly(
          include(id: led1.id, name: "A", balance: cost("$3")),
          include(id: led2.id, name: "B", balance: cost("$0")),
        ),
        single_ledger_lines_first_page: [],
        single_ledger_page_count: 0,
        total_balance: cost("$3"),
      )
    end

    it "returns the first page of ledger lines if the member has a single ledger" do
      led1 = Suma::Fixtures.ledger.member(member).create(name: "A")
      recent_xaction = bookfac.from(led1).create(apply_at: 20.days.ago, amount_cents: 100)
      old_xaction = bookfac.to(led1).create(apply_at: 80.days.ago, amount_cents: 400)

      get "/v1/ledgers/overview"

      expect(last_response).to have_status(200)
      expect(last_response_json_body).to include(
        ledgers: have_length(1),
        total_balance: cost("$3"),
        single_ledger_page_count: 1,
        single_ledger_lines_first_page: match(
          [
            include(amount: cost("-$1"), at: match_time(recent_xaction.apply_at)),
            include(amount: cost("$4"), at: match_time(old_xaction.apply_at)),
          ],
        ),
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
  end
end
