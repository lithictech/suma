# frozen_string_literal: true

require "suma/admin_api/search"

RSpec.describe Suma::AdminAPI::Search, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create }

  before(:each) do
    login_as_admin(admin)
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
    it "returns matching bank accounts" do
      o1 = Suma::Fixtures.bank_account.verified.create(name: "abc")
      o2 = Suma::Fixtures.bank_account.verified.create(name: "xyz")

      post "/v1/search/payment_instruments", q: "abc"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(items: have_same_ids_as(o1))
    end

    it "can search a card last 4" do
      o1 = Suma::Fixtures.card.with_stripe("last4" => "1234").create
      o2 = Suma::Fixtures.card.with_stripe("last4" => "5678").create

      post "/v1/search/payment_instruments", q: "5678"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(items: have_same_ids_as(o2))
    end

    it "can filter on payment method type" do
      o1 = Suma::Fixtures.bank_account.verified.create(name: "5678")
      o2 = Suma::Fixtures.card.with_stripe("last4" => "5678").create

      post "/v1/search/payment_instruments", q: "5678", types: ["bank_account"]

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(items: have_same_ids_as(o1))
    end
  end

  describe "POST /v1/search/translations" do
    it "returns ranked distinct translated texts" do
      Suma::TranslatedText.create(en: "quickly fast brown")
      Suma::TranslatedText.create(en: "the quick brown fox")
      Suma::TranslatedText.create(en: "the quick brown fox")
      Suma::TranslatedText.create(en: "jumps over the lazy dog")
      Suma::TranslatedText.create(en: "jumps over the lazy dog")

      post "/v1/search/translations", q: "quick brown"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        items: [
          include(en: "the quick brown fox"),
          include(en: "quickly fast brown"),
        ],
      )
    end

    it "can search spanish" do
      Suma::TranslatedText.create(en: "the quick brown fox", es: "jumps over the lazy dog")
      Suma::TranslatedText.create(en: "jumps over the lazy dog", es: "the quick brown fox")

      post "/v1/search/translations", q: "quick brown", language: "es"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        items: [
          include(es: "the quick brown fox"),
        ],
      )
    end

    it "can filter for memos" do
      t1 = Suma::TranslatedText.create(en: "the quick brown fox", es: "est1")
      t2 = Suma::TranslatedText.create(en: "jumps over the lazy dog", es: "est2")
      Suma::Fixtures.book_transaction.create(memo: t2)

      post "/v1/search/translations", q: "brown fox", types: ["memo"]

      expect(last_response).to have_status(200)
      # Only t2 is attached to a ledger, so no results come back.
      expect(last_response).to have_json_body.that_includes(items: [])

      post "/v1/search/translations", q: "brown fox"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        items: [include(en: "the quick brown fox", es: start_with("est1"))],
      )
    end

    it "renders the label with the searched language" do
      Suma::TranslatedText.create(en: "fox english", es: "fox spanish")

      post "/v1/search/translations", q: "fox", language: "en"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(items: [include(label: "fox english")])

      post "/v1/search/translations", q: "fox", language: "es"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(items: [include(label: "fox spanish")])
    end
  end
end
