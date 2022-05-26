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
end
