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

  describe "GET /v1/meta/vendor_service_categories" do
    it "returns categories" do
      a = Suma::Fixtures.vendor_service_category(name: "A").create
      b = Suma::Fixtures.vendor_service_category.create(name: "B", parent: a)

      get "/v1/meta/vendor_service_categories"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        items: [
          {slug: "a", name: "A", label: "A"},
          {slug: "b", name: "B", label: "A - B"},
        ],
      )
    end
  end
end