# frozen_string_literal: true

require "suma/admin_api/payment_ledgers"

RSpec.describe Suma::AdminAPI::PaymentLedgers, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create }
  let(:platform_account) { Suma::Fixtures.payment_account.create(is_platform_account: true) }

  before(:each) do
    login_as_admin(admin)
  end

  describe "GET /v1/payment_ledgers/platform_ledgers" do
    it "returns all platform account ledgers" do
      u = Array.new(2) { Suma::Fixtures.ledger.create(account: platform_account) }
      non_platform_ledger = Suma::Fixtures.ledger.create

      get "/v1/payment_ledgers/platform_ledgers"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(items: have_same_ids_as(*u))
    end
  end
  describe "GET /v1/payment_ledgers/platform_ledgers/:id" do
    it "returns the platform account ledger" do
      platform_ledger = Suma::Fixtures.ledger.member(admin).create(account: platform_account)
      food_ledger = Suma::Fixtures.ledger.member(admin).create(name: "Food")
      Suma::Fixtures.book_transaction.from(platform_ledger).to(food_ledger).create
      Suma::Fixtures.book_transaction.from(food_ledger).to(platform_ledger).create

      get "/v1/payment_ledgers/platform_ledgers/#{platform_ledger.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: platform_ledger.id,
                                                            combined_book_transactions: have_length(2),)
    end

    it "403s if the item does not exist" do
      get "/v1/payment_ledgers/platform_ledgers/0"

      expect(last_response).to have_status(403)
    end
  end
end
