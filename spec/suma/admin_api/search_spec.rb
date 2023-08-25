# frozen_string_literal: true

require "suma/admin_api/search"

RSpec.describe Suma::AdminAPI::Search, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create }

  before(:each) do
    login_as_admin(admin)
  end

  describe "GET /v1/search/ledger" do
    it "returns receiving ledger along with platform ledger" do
      receiving_ledger = Suma::Fixtures.ledger.create(name: "abc")

      get "/v1/search/receiving_ledger", id: receiving_ledger.id

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        receiving_ledger: include(id: receiving_ledger.id),
        platform_ledger: include(id: platform_cash_ledger.id),
      )
    end
  end

  describe "POST /v1/search/ledgers" do
    it "returns matching ledgers" do
      o1 = Suma::Fixtures.ledger.create(name: "abc")
      o2 = Suma::Fixtures.ledger.create(name: "xyz")

      post "/v1/search/ledgers", q: "abc"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(items: have_same_ids_as(o1))
    end
  end

  describe "POST /v1/search/ledgers/lookup" do
    it "returns ledgers with the given ids and keys" do
      o1 = Suma::Fixtures.ledger.create(name: "abc")
      o2 = Suma::Fixtures.ledger.create(name: "xyz")
      platform = Suma::Fixtures::Ledgers.ensure_platform_cash

      post "/v1/search/ledgers/lookup", ids: [o1.id, -10], platform_categories: ["cash", "mobility"]

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        by_id: match("#{o1.id}": include(id: o1.id)),
        platform_by_category: match(cash: include(id: platform.id)),
      )
    end
  end

  describe "POST /v1/search/payment_instruments" do
    it "returns matching payment instruments" do
      o1 = Suma::Fixtures.bank_account.verified.create(name: "abc")
      o2 = Suma::Fixtures.bank_account.verified.create(name: "xyz")

      post "/v1/search/payment_instruments", q: "abc"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(items: have_same_ids_as(o1))
    end

    it "can filter on payment method type" do
      # Cannot do this until we have multiple payment methods
    end
  end
end
