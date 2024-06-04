# frozen_string_literal: true

require "suma/admin_api/search"

RSpec.describe Suma::AdminAPI::Search, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create(name: "Bob") }

  before(:each) do
    login_as(admin)
  end

  describe "POST /v1/search/ledgers" do
    it "returns matching ledgers" do
      o1 = Suma::Fixtures.ledger.create(name: "abc")
      o2 = Suma::Fixtures.ledger.create(name: "xyz")

      post "/v1/search/ledgers", q: "abc"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(items: have_same_ids_as(o1))
    end

    describe "with the words 'platform' or 'suma' in the search string" do
      it "replaces the words 'platform' and 'suma' with the platform account" do
        o1 = Suma::Fixtures.ledger.create(name: "abc")
        o2 = Suma::Fixtures.ledger.create(name: "xyz")
        pa = Suma::Payment::Account.lookup_platform_account
        p1 = Suma::Fixtures.ledger.create(name: "abc", account: pa)
        p2 = Suma::Fixtures.ledger.create(name: "xyz", account: pa)

        post "/v1/search/ledgers", q: "platform abc"

        expect(last_response).to have_status(200)
        expect(last_response).to have_json_body.that_includes(items: have_same_ids_as(p1))

        post "/v1/search/ledgers", q: "suma"

        expect(last_response).to have_status(200)
        expect(last_response).to have_json_body.that_includes(items: have_same_ids_as(p1, p2))
      end

      it "includes non-platform ledgers with the search string" do
        o1 = Suma::Fixtures.ledger.create(name: "suma abc")
        o2 = Suma::Fixtures.ledger.create(name: "suma xyz")
        pa = Suma::Payment::Account.lookup_platform_account
        p1 = Suma::Fixtures.ledger.create(name: "abc", account: pa)
        p2 = Suma::Fixtures.ledger.create(name: "xyz", account: pa)

        post "/v1/search/ledgers", q: "suma abc"

        expect(last_response).to have_status(200)
        expect(last_response).to have_json_body.that_includes(items: have_same_ids_as(o1, p1))
      end
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

  describe "POST /v1/search/offerings" do
    it "returns matching offerings" do
      o1 = Suma::Fixtures.offering.create(description: Suma::Fixtures.translated_text(en: "abc farmers market").create)
      o2 = Suma::Fixtures.offering.create(description: Suma::Fixtures.translated_text(en: "test").create)

      post "/v1/search/offerings", q: "abc"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(items: have_same_ids_as(o1))
    end

    it "returns all offerings if no query" do
      o1 = Suma::Fixtures.offering.create(description: Suma::Fixtures.translated_text(en: "z market").create)
      o2 = Suma::Fixtures.offering.create(description: Suma::Fixtures.translated_text(en: "a market").create)

      post "/v1/search/offerings"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(items: have_same_ids_as(o2, o1))
    end
  end

  describe "POST /v1/search/vendors" do
    it "returns matching vendors" do
      v1 = Suma::Fixtures.vendor.create(name: "abc farmers market")
      v2 = Suma::Fixtures.vendor.create(name: "test")

      post "/v1/search/vendors", q: "abc"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(items: have_same_ids_as(v1))
    end

    it "returns all results if no query" do
      v1 = Suma::Fixtures.vendor.create(name: "x market")
      v2 = Suma::Fixtures.vendor.create(name: "a market")

      post "/v1/search/vendors"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(items: have_same_ids_as(v2, v1).ordered)
    end
  end

  describe "POST /v1/search/members" do
    it "returns matching active members" do
      m1 = Suma::Fixtures.member.create(name: "Hector Gambino")
      m2 = Suma::Fixtures.member.create(name: "test")
      inactive = Suma::Fixtures.member.create(name: "hector")
      inactive.soft_delete

      post "/v1/search/members", q: "hector"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(items: have_same_ids_as(m1))
    end

    it "returns matching members label" do
      m1 = Suma::Fixtures.member.create(name: "Hector Gambino")

      post "/v1/search/members", q: "hector"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(items: [include(label: "(#{m1.id}) #{m1.name}")])
    end

    it "returns all results in descending order if no query" do
      m1 = Suma::Fixtures.member.create(name: "x member")
      m2 = Suma::Fixtures.member.create(name: "a member")

      post "/v1/search/members"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(items: have_same_ids_as(m2, admin, m1).ordered)
    end
  end

  describe "POST /v1/search/organizations" do
    it "returns matching organizations" do
      m1 = Suma::Fixtures.organization.create(name: "hacienda abc")
      m2 = Suma::Fixtures.organization.create(name: "test")

      post "/v1/search/organizations", q: "hacienda"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(items: have_same_ids_as(m1))
    end

    it "returns matching organizations label" do
      m1 = Suma::Fixtures.organization.create(name: "Hacienda Abc")

      post "/v1/search/organizations", q: "hac"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(items: [include(label: "Hacienda Abc")])
    end

    it "returns all results in descending order if no query" do
      m1 = Suma::Fixtures.organization.create(name: "x organization")
      m2 = Suma::Fixtures.organization.create(name: "an org")

      post "/v1/search/organizations"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(items: have_same_ids_as(m2, m1).ordered)
    end
  end
end
