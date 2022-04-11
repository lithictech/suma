# frozen_string_literal: true

require "suma/api/mobility"

RSpec.describe Suma::API::Mobility, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:customer) { Suma::Fixtures.customer.create }

  before(:each) do
    login_as(customer)
  end

  describe "GET /v1/mobility/map" do
    it "returns the location of all vehicles within the requested bounds" do
      fac = Suma::Fixtures.mobility_vehicle(vendor: Suma::Fixtures.vendor.create)
      v1 = fac.loc(10, 100).escooter.create
      v2 = fac.loc(20, 120).escooter.create
      bike = fac.loc(20, 120).ebike.create
      v3 = fac.loc(30, 130).escooter.create

      get "/v1/mobility/map", minloc: [15, 110], maxloc: [25, 125]

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(
          escooter: [
            {c: [200_000_000, 1_200_000_000], p: 0},
          ],
          ebike: [
            {c: [200_000_000, 1_200_000_000], p: 0},
          ],
        )
    end

    it "handles coordinate precision" do
      Suma::Fixtures.mobility_vehicle.loc(-0.5, 100).escooter.create

      get "/v1/mobility/map", minloc: [-10, 50], maxloc: [50, 150]

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(
          precision: 10_000_000,
          escooter: [
            {c: [-5_000_000, 1_000_000_000], p: 0},
          ],
        )
      expect(last_response_json_body[:escooter][0][:c][0].to_f / last_response_json_body[:precision]).to eq(-0.5)
    end

    it "tells the frontend to refresh in 30 seconds" do
      get "/v1/mobility/map", minloc: [-10, 50], maxloc: [50, 150]

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(refresh: 30_000)
    end

    it "can limit results to the requested type" do
      fac = Suma::Fixtures.mobility_vehicle(vendor: Suma::Fixtures.vendor.create)
      scooter = fac.loc(20, 121).escooter.create
      bike = fac.loc(20, 120).ebike.create

      get "/v1/mobility/map", minloc: [15, 110], maxloc: [25, 125], types: ["ebike"]

      expect(last_response).to have_status(200)
      expect(last_response_json_body).to include(
        :providers, ebike: [
          {c: [200_000_000, 1_200_000_000], p: 0},
        ],
      )
      expect(last_response_json_body).to_not include(:escooter)
    end

    it "references providers by their index" do
      v1 = Suma::Fixtures.mobility_vehicle.loc(20, 120).ebike.create
      v2 = Suma::Fixtures.mobility_vehicle.loc(20, 120).ebike.create
      v2 = Suma::Fixtures.mobility_vehicle.loc(20, 120).ebike.create(vendor: v1.vendor)

      get "/v1/mobility/map", minloc: [15, 110], maxloc: [25, 125]

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(
          providers: have_length(2),
          ebike: contain_exactly(
            include(p: 0),
            include(p: 1),
            include(p: 0),
          ),
        )
    end

    it "disambiguates vehicles of the same type and provider at the same location" do
      p = Suma::Fixtures.vendor.create
      fac = Suma::Fixtures.mobility_vehicle
      bike1_provider1_loc1 = fac.loc(20, 120).ebike.create(vendor: p, vehicle_id: "111")
      bike2_provider1_loc1 = fac.loc(20, 120).ebike.create(vendor: p, vehicle_id: "211")
      bike3_provider1_loc2 = fac.loc(40, 140).ebike.create(vendor: p, vehicle_id: "312")
      scooter1_provider1_loc1 = fac.loc(20, 120).escooter.create(vendor: p, vehicle_id: "s111")
      bike1_provider2_loc1 = fac.loc(20, 120).ebike.create(vehicle_id: "121")

      get "/v1/mobility/map", minloc: [-90, -180], maxloc: [90, 180]

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(
          escooter: [
            {c: [200_000_000, 1_200_000_000], p: 0},
          ],
          ebike: [
            {c: [200_000_000, 1_200_000_000], p: 0, d: "111"},
            {c: [200_000_000, 1_200_000_000], p: 0, d: "211"},
            {c: [400_000_000, 1_400_000_000], p: 0},
            {c: [200_000_000, 1_200_000_000], p: 1},
          ],
        )
    end

    it "401s if not logged in" do
      logout
      get "/v1/mobility/map", minloc: [15, 110], maxloc: [25, 125]
      expect(last_response).to have_status(401)
    end
  end

  describe "GET /v1/mobility/vehicle" do
    let(:fac) {  Suma::Fixtures.mobility_vehicle }
    let(:prov) { Suma::Fixtures.vendor.create }

    it "returns information about the requested vehicle" do
      b1 = fac.loc(0.5, 179.5).ebike.create(vendor: prov)
      b2 = fac.loc(30, 120).ebike.create(vendor: prov)
      s3 = fac.loc(0.5, 179.5).escooter.create(vendor: prov)

      get "/v1/mobility/vehicle", loc: [5_000_000, 1_795_000_000], provider: prov.slug, type: "ebike"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(
          :vendor,
          vehicle_id: b1.vehicle_id,
          loc: [5_000_000, 1_795_000_000],
        )
    end

    it "can look up a vehicle that must be disambiguated" do
      fac.loc(0.5, 179.5).ebike.create(vendor: prov)
      fac.loc(0.5, 179.5).ebike.create(vendor: prov, vehicle_id: "abc")

      get "/v1/mobility/vehicle",
          loc: [5_000_000, 1_795_000_000], provider: prov.slug, type: "ebike", disambiguator: "abc"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(vehicle_id: "abc")
    end

    it "403s if no vehicle is found" do
      fac.ebike.create(vendor: prov)

      get "/v1/mobility/vehicle", loc: [0, 0], provider: prov.slug, type: "ebike"

      expect(last_response).to have_status(403)
      expect(last_response).to have_json_body.that_includes(error: include(code: "vehicle_not_found"))
    end

    it "403s if no vehicle with a disambiguator is found" do
      fac.loc(0, 0).ebike.create(vendor: prov, vehicle_id: "xyz")
      fac.loc(0, 0).ebike.create(vendor: prov, vehicle_id: "abc")

      get "/v1/mobility/vehicle", loc: [0, 0], provider: prov.slug, type: "ebike", disambiguator: "rst"

      expect(last_response).to have_status(403)
      expect(last_response).to have_json_body.that_includes(error: include(code: "vehicle_not_found"))
    end

    it "403s if the vehicle must be disambiguated but no disambiguator is passed in" do
      fac.loc(0, 0).ebike.create(vendor: prov, vehicle_id: "xyz")
      fac.loc(0, 0).ebike.create(vendor: prov, vehicle_id: "abc")

      get "/v1/mobility/vehicle", loc: [0, 0], provider: prov.slug, type: "ebike"

      expect(last_response).to have_status(400)
      expect(last_response).to have_json_body.that_includes(error: include(code: "disambiguation_required"))
    end

    it "401s if not logged in" do
      logout
      get "/v1/mobility/vehicle", loc: [0, 0], provider: "a", type: "ebike"
      expect(last_response).to have_status(401)
    end
  end
end
