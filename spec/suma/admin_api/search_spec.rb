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

    it "errors without role access" do
      replace_roles(admin, Suma::Role.cache.noop_admin)

      post "/v1/search/ledgers", q: "abc"

      expect(last_response).to have_status(403)
      expect(last_response).to have_json_body.that_includes(error: include(code: "role_check"))
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

    it "errors without role access" do
      replace_roles(admin, Suma::Role.cache.noop_admin)

      post "/v1/search/ledgers/lookup", ids: [], platform_categories: []

      expect(last_response).to have_status(403)
      expect(last_response).to have_json_body.that_includes(error: include(code: "role_check"))
    end
  end

  describe "POST /v1/search/payment_instruments", :hybrid_search do
    it "errors without role access" do
      replace_roles(admin, Suma::Role.cache.noop_admin)

      post "/v1/search/payment_instruments", q: "abc", purpose: :funding

      expect(last_response).to have_status(403)
      expect(last_response).to have_json_body.that_includes(error: include(code: "role_check"))
    end

    it "returns matching payment instruments" do
      ba_abc = Suma::Fixtures.bank_account.verified.create(name: "abc")
      Suma::Fixtures.bank_account.verified.create(name: "abc").soft_delete
      ba_xyz = Suma::Fixtures.bank_account.verified.create(name: "xyz")
      card_abc = Suma::Fixtures.card.with_stripe("brand" => "abc").create
      Suma::Fixtures.card.with_stripe("brand" => "abc").create.soft_delete
      card_xyz = Suma::Fixtures.card.with_stripe("brand" => "xyz").create

      Suma::Payment::BankAccount.hybrid_search_reindex_all
      Suma::Payment::Card.hybrid_search_reindex_all

      post "/v1/search/payment_instruments", q: "abc", purpose: :funding

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(items: have_same_ids_as(ba_abc, card_abc))
    end

    it "can filter on payment method type" do
      ba = Suma::Fixtures.bank_account.verified.create(name: "myaccount")
      card = Suma::Fixtures.card.with_stripe("brand" => "myaccount").create
      Suma::Payment::BankAccount.hybrid_search_reindex_all
      Suma::Payment::Card.hybrid_search_reindex_all

      post "/v1/search/payment_instruments", q: "myaccount", types: ["card"], purpose: :funding

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(items: have_same_ids_as(card))
    end

    it "can filter on purpose" do
      ba = Suma::Fixtures.bank_account.verified.create
      card = Suma::Fixtures.card.create
      Suma::Payment::BankAccount.hybrid_search_reindex_all
      Suma::Payment::Card.hybrid_search_reindex_all

      post "/v1/search/payment_instruments", q: "*", purpose: :payout

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(items: have_same_ids_as(ba))
    end
  end

  describe "POST /v1/search/products" do
    it "returns matching products" do
      o1 = Suma::Fixtures.product.create
      o1.name.update(en: "abc")
      o2 = Suma::Fixtures.product.create

      post "/v1/search/products", q: "abc"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(items: have_same_ids_as(o1))
    end

    it "errors without role access" do
      replace_roles(admin, Suma::Role.cache.noop_admin)

      post "/v1/search/products", q: "abc"

      expect(last_response).to have_status(403)
      expect(last_response).to have_json_body.that_includes(error: include(code: "role_check"))
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
    it "errors without role access" do
      replace_roles(admin, Suma::Role.cache.noop_admin)

      post "/v1/search/offerings", q: "abc"

      expect(last_response).to have_status(403)
      expect(last_response).to have_json_body.that_includes(error: include(code: "role_check"))
    end

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
    it "errors without role access" do
      replace_roles(admin, Suma::Role.cache.noop_admin)

      post "/v1/search/vendors"

      expect(last_response).to have_status(403)
      expect(last_response).to have_json_body.that_includes(error: include(code: "role_check"))
    end

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
    it "errors without role access" do
      replace_roles(admin, Suma::Role.cache.noop_admin)

      post "/v1/search/members", q: "hector"

      expect(last_response).to have_status(403)
      expect(last_response).to have_json_body.that_includes(error: include(code: "role_check"))
    end

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
    it "errors without role access" do
      replace_roles(admin, Suma::Role.cache.noop_admin)

      post "/v1/search/organizations"

      expect(last_response).to have_status(403)
      expect(last_response).to have_json_body.that_includes(error: include(code: "role_check"))
    end

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

  describe "POST /v1/search/roles" do
    it "returns matching roles, using slug naming" do
      r1 = Suma::Role.create(name: "sponge_bob")
      r2 = Suma::Role.create(name: "patrick")

      post "/v1/search/roles", q: "sponge bob"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(items: [include(id: r1.id, label: "Sponge Bob")])
    end

    it "returns all results in descending order if no query" do
      r1 = Suma::Role.create(name: "x role")
      r2 = Suma::Role.create(name: "addmin")

      post "/v1/search/roles"

      expect(last_response).to have_status(200)
      expect(last_response_json_body[:items].first).to include(name: r2.name)
      expect(last_response_json_body[:items].last).to include(name: r1.name)
    end
  end

  describe "POST /v1/search/static_strings" do
    it "returns strings" do
      ss1 = Suma::Fixtures.static_string.create(namespace: "other", key: "mobility.rates.foo")
      ss2 = Suma::Fixtures.static_string.create(namespace: "strings", key: "mobility.rates.foo")
      ss3 = Suma::Fixtures.static_string.create(namespace: "strings", key: "mobility.rates.foo2", deprecated: true)
      ss4 = Suma::Fixtures.static_string.create(namespace: "strings", key: "mobility.foo")
      ss5 = Suma::Fixtures.static_string.create(namespace: "strings", key: "foo")
      ss6 = Suma::Fixtures.static_string.create(namespace: "strings", key: "mobility.rates.bar")

      post "/v1/search/static_strings", q: "rates"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(items: have_same_ids_as(ss1, ss2, ss6))

      post "/v1/search/static_strings", q: "foo", prefix: "mobility.rates."

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(items: have_same_ids_as(ss1, ss2))

      post "/v1/search/static_strings", q: "foo", namespace: "other"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(items: have_same_ids_as(ss1))

      post "/v1/search/static_strings", q: "foo", namespace: "strings", prefix: "mobility."

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(items: have_same_ids_as(ss2, ss4))
    end

    it "qualifies the entity label if namespace is not provided" do
      Suma::Fixtures.static_string.create(namespace: "str", key: "foo")

      post "/v1/search/static_strings", q: "foo"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(items: contain_exactly(include(label: "str.foo")))

      post "/v1/search/static_strings", q: "foo", namespace: "str"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(items: contain_exactly(include(label: "foo")))
    end
  end

  describe "POST /v1/search/vendor_services" do
    it "errors without role access" do
      replace_roles(admin, Suma::Role.cache.noop_admin)

      post "/v1/search/vendor_services", q: "ride"

      expect(last_response).to have_status(403)
      expect(last_response).to have_json_body.that_includes(error: include(code: "role_check"))
    end

    it "returns matching vendor services" do
      vs1 = Suma::Fixtures.vendor_service.create(external_name: "ride connection")
      vs2 = Suma::Fixtures.organization.create(name: "test")

      post "/v1/search/vendor_services", q: "ride connection"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(items: have_same_ids_as(vs1))
    end

    it "returns matching vendor services label" do
      Suma::Fixtures.vendor_service.create(external_name: "Ride connection")

      post "/v1/search/vendor_services", q: "ride"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(items: [include(label: "Ride connection")])
    end

    it "returns all results in descending order if no query" do
      vs1 = Suma::Fixtures.vendor_service.create(external_name: "x vendor service")
      vs2 = Suma::Fixtures.vendor_service.create(external_name: "a vendor service")

      post "/v1/search/vendor_services"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(items: have_same_ids_as(vs2, vs1).ordered)
    end
  end

  describe "POST /v1/search/vendor_service_rates" do
    it "errors without role access" do
      replace_roles(admin, Suma::Role.cache.noop_admin)

      post "/v1/search/vendor_service_rates", q: "ride"

      expect(last_response).to have_status(403)
      expect(last_response).to have_json_body.that_includes(error: include(code: "role_check"))
    end

    it "returns matching vendor service rates" do
      rate1 = Suma::Fixtures.vendor_service_rate.create(name: "ratex")
      rate2 = Suma::Fixtures.organization.create(name: "ratey")

      post "/v1/search/vendor_service_rates", q: "ratex"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(items: have_same_ids_as(rate1))
    end
  end

  describe "POST /v1/search/commerce_offerings" do
    it "errors without role access" do
      replace_roles(admin, Suma::Role.cache.noop_admin)

      post "/v1/search/commerce_offerings", q: "sum"

      expect(last_response).to have_status(403)
      expect(last_response).to have_json_body.that_includes(error: include(code: "role_check"))
    end

    it "returns matching commerce offerings" do
      o1 = Suma::Fixtures.offering.create(description: Suma::Fixtures.translated_text.create(en: "Summer FM EN"))
      o2 = Suma::Fixtures.offering.create(description: Suma::Fixtures.translated_text.create(en: "test"))

      post "/v1/search/commerce_offerings", q: "sum"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(items: have_same_ids_as(o1))
    end

    it "returns matching vendor services label" do
      Suma::Fixtures.offering.create(description: Suma::Fixtures.translated_text.create(en: "December Holidays"))

      post "/v1/search/commerce_offerings", q: "holi"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(items: [include(label: "December Holidays")])
    end

    it "returns all results in descending order if no query" do
      o1 = Suma::Fixtures.offering.create(description: Suma::Fixtures.translated_text.create(en: "x holiday"))
      o2 = Suma::Fixtures.offering.create(description: Suma::Fixtures.translated_text.create(en: "a holiday"))

      post "/v1/search/commerce_offerings"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(items: have_same_ids_as(o2, o1).ordered)
    end
  end

  describe "POST /v1/search/programs" do
    it "returns matching programs" do
      o1 = Suma::Fixtures.program.create(name: Suma::Fixtures.translated_text.create(en: "PWB funds"))
      o2 = Suma::Fixtures.program.create(name: Suma::Fixtures.translated_text.create(en: "test"))

      post "/v1/search/programs", q: "pwb"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(items: have_same_ids_as(o1))
    end

    it "returns matching program label" do
      Suma::Fixtures.program.create(name: Suma::Fixtures.translated_text.create(en: "PWB funds"))

      post "/v1/search/programs", q: "funds"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(items: [include(label: "PWB funds")])
    end

    it "returns all results in descending order if no query" do
      o1 = Suma::Fixtures.program.create(name: Suma::Fixtures.translated_text.create(en: "x special"))
      o2 = Suma::Fixtures.program.create(name: Suma::Fixtures.translated_text.create(en: "a special"))

      post "/v1/search/programs"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(items: have_same_ids_as(o2, o1).ordered)
    end
  end
end
