# frozen_string_literal: true

require "suma/admin_api/financials"

RSpec.describe Suma::AdminAPI::Financials, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create }

  before(:each) do
    login_as(admin)
  end

  describe "GET /v1/financials/platform_status" do
    it "returns platform status financials" do
      pa = Suma::Payment::Account.lookup_platform_account
      cash = Suma::Payment.ensure_cash_ledger(pa)
      Suma::Fixtures.funding_transaction.with_fake_strategy.create
      Suma::Fixtures.payout_transaction.with_fake_strategy.create
      Suma::Fixtures.book_transaction.from(cash).create
      Suma::Fixtures.book_transaction.to(cash).create

      get "/v1/financials/platform_status"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(:platform_ledgers, :funding)
    end
  end
end
