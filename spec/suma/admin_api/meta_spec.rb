# frozen_string_literal: true

require "suma/admin_api/meta"

RSpec.describe Suma::AdminAPI::Meta, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create }

  before(:each) do
    login_as(admin)
  end

  describe "GET /v1/meta/currencies" do
    it "returns supported currencies" do
      Suma::Fixtures.supported_currency.create(funding_minimum_cents: 500)

      get "/v1/meta/currencies"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        items: [{symbol: "$", code: "USD"}],
      )
    end
  end

  describe "GET /v1/meta/geographies" do
    it "returns supported geographies" do
      Suma::Fixtures.supported_geography.in_usa.state("Oregon").create
      Suma::Fixtures.supported_geography.in_usa.state("North Carolina", "NC").create
      Suma::Fixtures.supported_geography.in_country("Iceland").state("Reykjavik").create

      get "/v1/meta/geographies"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        countries: [
          {label: "Iceland", value: "Iceland"},
          {label: "USA", value: "United States of America"},
        ],
        provinces: [
          {label: "NC", value: "North Carolina", country: include(label: "USA")},
          {label: "Oregon", value: "Oregon", country: include(label: "USA")},
          {label: "Reykjavik", value: "Reykjavik", country: include(label: "Iceland")},
        ],
      )
    end
  end

  describe "GET /v1/meta/vendor_service_categories" do
    it "returns categories" do
      a = Suma::Fixtures.vendor_service_category(name: "A").create
      b = Suma::Fixtures.vendor_service_category.create(name: "B", parent: a)

      get "/v1/meta/vendor_service_categories"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        items: [include(label: "A"), include(label: "A - B")],
      )
    end
  end

  describe "GET /v1/meta/programs" do
    it "returns programs" do
      p1 = Suma::Fixtures.program.create(name: Suma::Fixtures.translated_text.create(en: "b"))
      p2 = Suma::Fixtures.program.create(name: Suma::Fixtures.translated_text.create(en: "a"))
      p3 = Suma::Fixtures.program.create(name: Suma::Fixtures.translated_text.create(en: "c"))

      get "/v1/meta/programs"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        items: have_same_ids_as(p2, p1, p3).ordered,
      )
    end
  end

  describe "GET /v1/meta/resource_access" do
    it "returns resource access info" do
      get "/v1/meta/resource_access"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        vendor_account: ["admin_commerce", "admin_commerce"],
      )
    end
  end
end
