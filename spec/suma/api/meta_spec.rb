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

    it "excludes organizations with a negative ordinal" do
      Suma::Fixtures.organization.create(name: "ord-1", ordinal: -1)
      Suma::Fixtures.organization.create(name: "ord1", ordinal: 1)

      get "/v1/meta/supported_organizations"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        items: [
          {name: "ord1"},
        ],
      )
    end
  end

  describe "GET /v1/meta/static_strings/<locale>/stripe", :static_strings do
    it "returns stripe error codes and their localized messages" do
      Suma::Fixtures.static_string.text("hi").create(namespace: "strings", key: "errors.card_invalid_zip")
      Suma::I18n::StaticStringRebuilder.instance.rebuild_outdated

      get "/v1/meta/static_strings/en/stripe"

      expect(last_response).to have_status(200)
      expect(last_response_json_body).to eq({errors: {incorrect_zip: ["s", "hi"]}})
    end
  end

  describe "GET /v1/meta/static_strings/<locale>/<namespace>", :static_strings do
    it "returns the static string file from the database" do
      Suma::Fixtures.static_string.text("hi").create(namespace: "forms", key: "s1")
      Suma::I18n::StaticStringRebuilder.instance.rebuild_outdated

      get "/v1/meta/static_strings/en/forms"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(s1: ["s", "hi"])
    end

    it "sets the last-modified header" do
      t = Time.parse("2020-01-01T12:00:00Z")
      Suma::Fixtures.static_string.text("hi").create(namespace: "x", modified_at: t)
      Suma::I18n::StaticStringRebuilder.instance.rebuild_outdated

      get "/v1/meta/static_strings/en/x"

      expect(last_response).to have_status(200)
      expect(last_response.headers["last-modified"]).to eq("Wed, 01 Jan 2020 12:00:00 GMT")
    end

    it "304s if not modified" do
      # Test this explicitly since we're using sendfile ourselves, and Rack may assume we're using a reverse proxy
      t = Time.parse("2020-01-01T12:00:00Z")
      Suma::Fixtures.static_string.text("hi").create(namespace: "x", modified_at: t)
      Suma::I18n::StaticStringRebuilder.instance.rebuild_outdated

      header "if-modified-since", (t + 1.year).httpdate

      get "/v1/meta/static_strings/en/x"

      expect(last_response).to have_status(304)
    end

    it "ignores an invalid header time" do
      Suma::Fixtures.static_string.text("hi").create(namespace: "x")
      Suma::I18n::StaticStringRebuilder.instance.rebuild_outdated

      header "if-modified-since", "abcfake"

      get "/v1/meta/static_strings/en/x"

      expect(last_response).to have_status(200)
    end

    it "403s for an invalid namespace" do
      get "/v1/meta/static_strings/en/x"

      expect(last_response).to have_status(403)
    end
  end
end
