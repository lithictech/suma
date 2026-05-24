# frozen_string_literal: true

require "suma/admin_api/bank_accounts"
require "suma/api/behaviors"

RSpec.describe Suma::AdminAPI::BankAccounts, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create }

  before(:each) do
    login_as(admin)
  end

  it_behaves_like "an endpoint with subroutes for related resources" do
    let(:detail_route) do
      "/v1/bank_accounts/#{Suma::Fixtures.bank_account.create.id}"
    end
  end

  describe "GET /v1/bank_accounts" do
    it "returns all bank_accounts" do
      c = Array.new(2) { Suma::Fixtures.bank_account.create }

      get "/v1/bank_accounts"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(items: have_same_ids_as(*c))
    end

    it_behaves_like "an endpoint capable of search" do
      let(:url) { "/v1/bank_accounts" }
      let(:search_term) { "zzz" }

      def make_matching_items
        return [Suma::Fixtures.bank_account(name: "zzz").create]
      end

      def make_non_matching_items
        return [Suma::Fixtures.bank_account(name: "wibble wobble").create]
      end
    end

    it_behaves_like "an endpoint with pagination" do
      let(:url) { "/v1/bank_accounts" }
      def make_item(i)
        # Sorting is newest first, so the first items we create need to the the oldest.
        created = Time.now - i.days
        return Suma::Fixtures.bank_account.create(created_at: created)
      end
    end

    it_behaves_like "an endpoint with member-supplied ordering" do
      let(:url) { "/v1/bank_accounts" }
      let(:order_by_field) { "name" }
      def make_item(i)
        return Suma::Fixtures.bank_account.create(
          created_at: Time.now + rand(1..100).days,
          name: i.to_s,
        )
      end
    end
  end

  describe "GET /v1/bank_accounts/:id" do
    it "returns the item" do
      c = Suma::Fixtures.bank_account.create

      get "/v1/bank_accounts/#{c.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: c.id)
    end

    it "403s if the item does not exist" do
      get "/v1/bank_accounts/0"

      expect(last_response).to have_status(403)
    end
  end
end
