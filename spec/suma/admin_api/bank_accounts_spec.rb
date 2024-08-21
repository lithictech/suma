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

  describe "GET /v1/bank_accounts/:id" do
    it "returns the account" do
      o = Suma::Fixtures.bank_account.create

      get "/v1/bank_accounts/#{o.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: o.id)
    end

    it "403s if the account does not exist" do
      get "/v1/bank_accounts/0"

      expect(last_response).to have_status(403)
    end
  end
end
