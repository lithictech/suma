# frozen_string_literal: true

require "suma/admin_api/payment_ledgers"
require "suma/api/behaviors"

RSpec.describe Suma::AdminAPI::PaymentLedgers, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create }
  let(:platform_account) { Suma::Fixtures.payment_account.platform.create }

  before(:each) do
    login_as(admin)
  end

  describe "GET /v1/payment_ledgers" do
    it "errors without role access" do
      replace_roles(admin, Suma::Role.cache.noop_admin)

      get "/v1/payment_ledgers"

      expect(last_response).to have_status(403)
      expect(last_response).to have_json_body.that_includes(error: include(code: "role_check"))
    end

    describe "ordering" do
      let!(:pe1) { Suma::Fixtures.ledger.create(account: platform_account) }
      let!(:non_pe1) { Suma::Fixtures.ledger.create }
      let!(:pe2) { Suma::Fixtures.ledger.create(account: platform_account) }
      let!(:non_pe2) { Suma::Fixtures.ledger.create }

      it "defaults to platform ledgers first" do
        get "/v1/payment_ledgers"

        expect(last_response).to have_status(200)
        expect(last_response).to have_json_body.
          that_includes(items: have_same_ids_as(pe2, pe1, non_pe2, non_pe1).ordered)
      end

      it "prefers user-supplied ordering" do
        get "/v1/payment_ledgers", order_by: "created_at"

        expect(last_response).to have_status(200)
        expect(last_response).to have_json_body.
          that_includes(items: have_same_ids_as(non_pe2, pe2, non_pe1, pe1).ordered)
      end
    end

    it_behaves_like "an endpoint capable of search" do
      let(:url) { "/v1/payment_ledgers" }
      let(:search_term) { "zzz" }

      def make_matching_items
        return [Suma::Fixtures.ledger(name: "FM zzz 2023").create]
      end

      def make_non_matching_items
        return [Suma::Fixtures.ledger(name: "wibble wobble").create]
      end
    end

    it_behaves_like "an endpoint with pagination" do
      let(:url) { "/v1/payment_ledgers" }
      def make_item(i)
        # Sorting is newest first, so the first items we create need to the the oldest.
        created = Time.now - i.days
        return Suma::Fixtures.ledger.create(created_at: created)
      end
    end

    it_behaves_like "an endpoint with member-supplied ordering" do
      let(:url) { "/v1/payment_ledgers" }
      let(:order_by_field) { "name" }
      def make_item(i)
        return Suma::Fixtures.ledger.create(
          created_at: Time.now + rand(1..100).days,
          name: i.to_s,
        )
      end
    end
  end

  describe "GET /v1/payment_ledgers/:id" do
    it "returns the ledger" do
      ledger = Suma::Fixtures.ledger.member(admin).create

      get "/v1/payment_ledgers/#{ledger.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: ledger.id)
    end

    it "403s if the item does not exist" do
      get "/v1/payment_ledgers/0"

      expect(last_response).to have_status(403)
    end
  end
end
