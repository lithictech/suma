# frozen_string_literal: true

require "suma/admin_api/meta"

RSpec.describe Suma::AdminAPI::Meta, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create }

  before(:each) do
    login_as_admin(admin)
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

  describe "GET /v1/meta/eligibility_constraints" do
    it "returns categories" do
      a = Suma::Fixtures.eligibility_constraint.create

      get "/v1/meta/eligibility_constraints"

      e expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        :statuses,
        items: have_same_ids_as(a),
      )
    end
  end
end
