# frozen_string_literal: true

require "suma/plaid"

RSpec.describe Suma::Plaid, :db do
  describe "Institutions" do
    describe "update_all" do
      it "paginates and upserts institutions" do
        described_class.bulk_sync_sleep = 0
        resp_json = load_fixture_data("plaid/institutions_get")
        headers = {"Content-Type" => "application/json"}
        req1 = stub_request(:post, "https://sandbox.plaid.com/institutions/get").
          with(
            body: {
              client_id: "plaidclientid",
              secret: "plaidsecret",
              count: 50,
              offset: 0,
              country_codes: ["US"],
              options: {include_optional_metadata: true},
            }.to_json,
          ).to_return(status: 200, body: resp_json.to_json, headers:)

        resp_json["institutions"].each { |inst| inst["institution_id"] = SecureRandom.hex(4) }
        req2 = stub_request(:post, "https://sandbox.plaid.com/institutions/get").
          with(
            body: {
              client_id: "plaidclientid",
              secret: "plaidsecret",
              count: 50,
              offset: 50,
              country_codes: ["US"],
              options: {include_optional_metadata: true},
            }.to_json,
          ).to_return(status: 200, body: resp_json.to_json, headers:)

        rand > 0.5 ? resp_json.delete("institutions") : (resp_json["institutions"] = [])
        req3 = stub_request(:post, "https://sandbox.plaid.com/institutions/get").
          with(
            body: {
              client_id: "plaidclientid",
              secret: "plaidsecret",
              count: 50,
              offset: 100,
              country_codes: ["US"],
              options: {include_optional_metadata: true},
            }.to_json,
          ).to_return(status: 200, body: resp_json.to_json, headers:)

        Suma::PlaidInstitution.update_all

        expect(Suma::PlaidInstitution.all).to have_length(10) # First 2 calls have results, last is empty so noops
        expect(req1).to have_been_made
        expect(req2).to have_been_made
        expect(req3).to have_been_made
      end
    end
  end
end
