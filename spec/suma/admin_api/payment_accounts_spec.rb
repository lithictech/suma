# frozen_string_literal: true

require "suma/admin_api/payment_accounts"
require "suma/api/behaviors"

RSpec.describe Suma::AdminAPI::PaymentAccounts, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create }

  before(:each) do
    login_as(admin)
  end

  it_behaves_like "an endpoint with subroutes for related resources" do
    let(:detail_route) do
      "/v1/payment_accounts/#{Suma::Fixtures.payment_account.create.id}"
    end
  end

  describe "GET /v1/payment_accounts/:id" do
    it "returns the object" do
      acct = Suma::Fixtures.payment_account.create

      get "/v1/payment_accounts/#{acct.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: acct.id)
    end

    it "403s if the item does not exist" do
      get "/v1/payment_accounts/0"

      expect(last_response).to have_status(403)
    end
  end
end
