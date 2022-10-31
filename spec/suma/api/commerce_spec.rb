# frozen_string_literal: true

require "suma/api/commerce"

RSpec.describe Suma::API::Commerce, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:member) { Suma::Fixtures.member.create }

  before(:each) do
    login_as(member)
  end

  describe "GET /v1/commerce/offerings" do
    it "returns only available offerings" do
      t1 = Time.parse("2021-01-01T00:00:00Z")
      t2 = Time.parse("2022-01-01T00:00:00Z")
      t3 = Time.parse("2023-01-01T00:00:00Z")
      offering1 = Suma::Fixtures.commerce_offering.period(t1, t2).create
      offering2 = Suma::Fixtures.commerce_offering.period(t1, t3).create
      Suma::Commerce::Offering.available_at(t2)

      get "/v1/commerce/offerings"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        items: contain_exactly(
          include(id: offering2.id),
        ),
      )
    end
  end
end
