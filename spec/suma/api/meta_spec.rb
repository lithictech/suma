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
      Suma::Fixtures.supported_currency.create(funding_minimum_cents: 500, funding_maximum_cents: 100_00)

      get "/v1/meta/supported_currencies"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        items: [
          {
            symbol: "$",
            code: "USD",
            funding_minimum_cents: 500,
            funding_maximum_cents: 100_00,
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

  describe "GET /v1/meta/supported_locales" do
    it "returns supported locales" do
      get "/v1/meta/supported_locales"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        items: [
          {
            code: "en",
            language: "English",
            native: "English",
          },
          {
            code: "es",
            language: "Spanish",
            native: "Español",
          },
        ],
      )
    end
  end

  describe "GET /v1/meta/supported_payment_methods" do
    it "returns supported methods" do
      get "/v1/meta/supported_payment_methods"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        items: ["bank_account", "card"],
      )
    end
  end

  describe "GET /v1/meta/geolocate_ip" do
    it "calls the configured ip geolocator" do
      body = {
        status: "success",
        country: "United States",
        countryCode: "US",
        region: "OR",
        regionName: "Oregon",
        city: "Portland",
        zip: "97202",
        lat: 45.4805,
        lon: -122.6363,
        timezone: "America/Los_Angeles",
        isp: "Comcast Cable Communications, LLC",
        org: "Comcast Cable Communications",
        as: "AS33490 Comcast Cable Communications, LLC",
        query: "24.21.167.222",
      }
      stub_request(:get, "http://ip-api.com/json/1.2.3.4").
        to_return(status: 200, body: body.to_json, headers: {"Content-Type" => "application/json"})

      header "X_FORWARDED_FOR", "1.2.3.4"

      get "/v1/meta/geolocate_ip"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes({lat: 45.4805, lng: -122.6363})
    end
  end

  describe "GET /v1/meta/supported_organizations" do
    it "returns supported organizations ordered by ordinal, name, and id" do
      orgb = Suma::Fixtures.organization.create(name: "b")
      orgc = Suma::Fixtures.organization.create(name: "c")
      orga = Suma::Fixtures.organization.create(name: "a")
      orgup = Suma::Fixtures.organization.create(name: "d", ordinal: 1)

      get "/v1/meta/supported_organizations"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        items: [
          {name: "d"},
          {name: "a"},
          {name: "b"},
          {name: "c"},
        ],
      )
    end
  end

  describe "GET /v1/meta/static_strings/<locale>" do
    it "returns the static string file from the database" do
      orgb = Suma::Fixtures.organization.create(name: "b")
      orgc = Suma::Fixtures.organization.create(name: "c")
      orga = Suma::Fixtures.organization.create(name: "a")
      orgup = Suma::Fixtures.organization.create(name: "d", ordinal: 1)

      get "/v1/meta/supported_organizations"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        items: [
          {name: "d"},
          {name: "a"},
          {name: "b"},
          {name: "c"},
        ],
      )
    end
  end
end
