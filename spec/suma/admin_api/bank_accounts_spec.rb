# frozen_string_literal: true

require "suma/admin_api/bank_accounts"
require "suma/api/behaviors"

RSpec.describe Suma::AdminAPI::BankAccounts, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.customer.admin.create }

  before(:each) do
    login_as_admin(admin)
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

  describe "DELETE /v1/bank_accounts/:id" do
    it "soft deletes account" do
      o = Suma::Fixtures.bank_account.create

      delete "/v1/bank_accounts/#{o.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: o.id)
      expect(o.refresh).to be_soft_deleted
    end
  end

  describe "PATCH /v1/bank_accounts/:id" do
    it "can verify the bank account" do
      o = Suma::Fixtures.bank_account.create

      patch "/v1/bank_accounts/#{o.id}", verified: true

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: o.id)
      expect(o.refresh).to be_verified
    end
  end
end
