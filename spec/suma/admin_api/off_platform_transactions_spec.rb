# frozen_string_literal: true

require "suma/admin_api/off_platform_transactions"
require "suma/api/behaviors"

RSpec.describe Suma::AdminAPI::OffPlatformTransactions, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create }

  before(:each) do
    login_as(admin)
  end

  describe "POST /v1/off_platform_transactions/create" do
    it "can create and process an off-platform funding transaction" do
      post "/v1/off_platform_transactions/create",
           type: :funding,
           amount: {cents: 500, currency: "USD"},
           transacted_at: "2022-01-01T12:00:00Z",
           note: "hello",
           check_or_transaction_number: "123"

      expect(last_response).to have_status(200)
      expect(last_response.headers).to include("Created-Resource-Admin")
      fx = Suma::Payment::Account.lookup_platform_account.originated_funding_transactions
      expect(fx).to contain_exactly(
        have_attributes(
          status: "cleared",
          amount: cost("$5"),
          strategy: have_attributes(
            note: "hello",
            check_or_transaction_number: "123",
            transacted_at: match_time("2022-01-01T12:00:00Z"),
          ),
        ),
      )
      expect(fx.first.audit_logs).to contain_exactly(
        have_attributes(
          event: "collect_funds",
          to_state: "cleared",
          actor: be === admin,
        ),
        have_attributes(
          event: "collect_funds",
          to_state: "collecting",
          actor: be === admin,
        ),
        have_attributes(
          event: "created",
          actor: be === admin,
          messages: [
            "amount=5.00",
            "transacted_at=2022-01-01 12:00:00 +0000",
            "note=hello",
            "check_or_transaction_number=123",
          ],
        ),
      )
    end

    it "can create and process an off-platform payout transaction" do
      post "/v1/off_platform_transactions/create",
           type: :payout,
           amount: {cents: 500, currency: "USD"},
           transacted_at: Time.now,
           note: "hello",
           check_or_transaction_number: "123"

      expect(last_response).to have_status(200)
      expect(last_response.headers).to include("Created-Resource-Admin")
      fx = Suma::Payment::Account.lookup_platform_account.originated_payout_transactions
      expect(fx).to contain_exactly(
        have_attributes(status: "settled", strategy: be_a(Suma::Payment::OffPlatformStrategy)),
      )
      expect(fx.first.audit_logs).to contain_exactly(
        have_attributes(event: "send_funds", to_state: "settled", actor: be === admin),
        have_attributes(event: "send_funds", to_state: "sending", actor: be === admin),
        have_attributes(
          event: "created",
          actor: be === admin,
        ),
      )
    end

    it "can use empty fields" do
      post "/v1/off_platform_transactions/create",
           type: :funding,
           amount: {cents: 500, currency: "USD"},
           transacted_at: Time.now,
           note: " x ",
           check_or_transaction_number: ""

      expect(last_response).to have_status(200)
      expect(last_response.headers).to include("Created-Resource-Admin")
      fx = Suma::Payment::Account.lookup_platform_account.originated_funding_transactions
      expect(fx.first.strategy).to have_attributes(note: "x", check_or_transaction_number: nil)
    end

    it "errors without role access" do
      replace_roles(admin, Suma::Role.cache.noop_admin)

      post "/v1/off_platform_transactions/create",
           type: :funding,
           amount: {cents: 500, currency: "USD"},
           transacted_at: Time.now,
           note: "x"

      expect(last_response).to have_status(403)
      expect(last_response).to have_json_body.that_includes(error: include(code: "role_check"))
    end
  end

  describe "GET /v1/off_platform_transactions:id" do
    let(:off_platform_strategy) { Suma::Payment::OffPlatformStrategy.create(note: "x", transacted_at: Time.now) }

    it "returns an off-platform funding transaction" do
      fx = Suma::Fixtures.funding_transaction.create(off_platform_strategy:)

      get "/v1/off_platform_transactions/#{off_platform_strategy.id}"

      expect(last_response).to have_status(200)
      expect(fx.refresh).to have_attributes(
        strategy: have_attributes(note: "x"),
      )
    end

    it "returns an off-platform payout transaction" do
      px = Suma::Fixtures.payout_transaction.create(off_platform_strategy:)

      get "/v1/off_platform_transactions/#{off_platform_strategy.id}"

      expect(last_response).to have_status(200)
      expect(px.refresh).to have_attributes(
        strategy: have_attributes(note: "x"),
      )
    end

    it "errors for an invalid id" do
      get "/v1/off_platform_transactions/1"

      expect(last_response).to have_status(403)
    end

    it "errors without role access" do
      replace_roles(admin, Suma::Role.cache.noop_admin)

      Suma::Fixtures.payout_transaction.create(off_platform_strategy:)

      get "/v1/off_platform_transactions/#{off_platform_strategy.id}"

      expect(last_response).to have_status(403)
      expect(last_response).to have_json_body.that_includes(error: include(code: "role_check"))
    end
  end

  describe "POST /v1/off_platform_transactions/:id" do
    let(:off_platform_strategy) { Suma::Payment::OffPlatformStrategy.create(note: "x", transacted_at: Time.now) }

    it "updates an off-platform funding transaction" do
      fx = Suma::Fixtures.funding_transaction.create(off_platform_strategy:)
      post "/v1/off_platform_transactions/#{off_platform_strategy.id}",
           amount: {cents: 500, currency: "USD"},
           transacted_at: "2022-01-01T12:00:00Z",
           note: "hello",
           check_or_transaction_number: "123"

      expect(last_response).to have_status(200)
      expect(fx.refresh).to have_attributes(
        amount: cost("$5"),
        strategy: have_attributes(
          transacted_at: match_time("2022-01-01T12:00:00Z"),
          note: "hello",
          check_or_transaction_number: "123",
        ),
      )
      expect(fx.audit_logs).to contain_exactly(
        have_attributes(
          event: "updated",
          messages: [
            "amount=5.00",
            "transacted_at=2022-01-01 12:00:00 UTC",
            "note=hello",
            "check_or_transaction_number=123",
          ],
        ),
      )
    end

    it "updates an off-platform payout transaction" do
      px = Suma::Fixtures.payout_transaction.create(off_platform_strategy:)

      post "/v1/off_platform_transactions/#{off_platform_strategy.id}",
           note: "hello",
           check_or_transaction_number: "123"

      expect(last_response).to have_status(200)
      expect(px.refresh.strategy).to have_attributes(note: "hello", check_or_transaction_number: "123")
      expect(px.audit_logs).to contain_exactly(
        have_attributes(event: "updated"),
      )
    end

    it "errors for an invalid id" do
      post "/v1/off_platform_transactions/1"

      expect(last_response).to have_status(403)
    end

    it "errors without role access" do
      replace_roles(admin, Suma::Role.cache.noop_admin)

      Suma::Fixtures.payout_transaction.create(off_platform_strategy:)

      post "/v1/off_platform_transactions/#{off_platform_strategy.id}"

      expect(last_response).to have_status(403)
      expect(last_response).to have_json_body.that_includes(error: include(code: "role_check"))
    end
  end
end
