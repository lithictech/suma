# frozen_string_literal: true

require "suma/api/meta"

RSpec.describe Suma::API::Meta, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }

  describe "GET /v1/meta/supported_geographies" do
    it "returns supported geographies" do
      Suma::Fixtures.supported_geography.in_usa.state("Oregon").create
      Suma::Fixtures.supported_geography.in_usa.state("North Carolina", "NC").create
      Suma::Fixtures.supported_geography.in_country("Iceland").state("Reykjavik").create

      get "/v1/meta/supported_geographies"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        countries: [
          {label: "Iceland", value: "Iceland"},
          {label: "USA", value: "United States of America"},
        ],
        provinces: [
          {label: "NC", value: "North Carolina", country_idx: 1},
          {label: "Oregon", value: "Oregon", country_idx: 1},
          {label: "Reykjavik", value: "Reykjavik", country_idx: 0},
        ],
      )
    end
  end

  describe "GET /v1/meta/supported_currencies" do
    it "returns supported currencies" do
      Suma::Fixtures.supported_currency.create(funding_minimum_cents: 500)

      get "/v1/meta/supported_currencies"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        items: [
          {
            symbol: "$",
            code: "USD",
            funding_minimum_cents: 500,
            funding_step_cents: 100,
            cents_in_dollar: 100,
            payment_method_types: ["bank_account"],
          },
        ],
      )
    end

    it "500s if there are no currencies" do
      get "/v1/meta/supported_currencies"

      expect(last_response).to have_status(500)
    end
  end
end
