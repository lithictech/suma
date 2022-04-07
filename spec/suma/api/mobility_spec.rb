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
      fac = Suma::Fixtures.mobility_vehicle(platform_partner: Suma::Fixtures.platform_partner.create)
      v1 = fac.loc(10, 100).escooter.create
      v2 = fac.loc(20, 120).escooter.create
      bike = fac.loc(20, 120).ebike.create
      v3 = fac.loc(30, 130).escooter.create

      get "/v1/mobility/map", minloc: [15, 110], maxloc: [25, 125]

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(
          escooter: [
            loc: [200_000_000, 1_200_000_000], pi: 0,
          ],
          ebike: [
            {loc: [200_000_000, 1_200_000_000], pi: 0},
          ],
        )
    end

    it "can limit results to the requested type" do
      fac = Suma::Fixtures.mobility_vehicle(platform_partner: Suma::Fixtures.platform_partner.create)
      scooter = fac.loc(20, 121).escooter.create
      bike = fac.loc(20, 120).ebike.create

      get "/v1/mobility/map", minloc: [15, 110], maxloc: [25, 125], types: ["ebike"]

      expect(last_response).to have_status(200)
      expect(last_response_json_body).to include(:providers, ebike: [
                                                   {loc: [200_000_000, 1_200_000_000], pi: 0},
                                                 ],)
      expect(last_response_json_body).to_not include(:escooter)
    end

    it "references providers by their index" do
      v1 = Suma::Fixtures.mobility_vehicle.loc(20, 120).ebike.create
      v2 = Suma::Fixtures.mobility_vehicle.loc(20, 120).ebike.create
      v2 = Suma::Fixtures.mobility_vehicle.loc(20, 120).ebike.create(platform_partner: v1.platform_partner)

      get "/v1/mobility/map", minloc: [15, 110], maxloc: [25, 125]

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(
          providers: have_length(2),
          ebike: contain_exactly(
            include(pi: 0),
            include(pi: 1),
            include(pi: 0),
          ),
        )
    end

    it "disambiguates vehicles of the same type and provider at the same location" do
      p = Suma::Fixtures.platform_partner.create
      fac = Suma::Fixtures.mobility_vehicle
      bike1_provider1_loc1 = fac.loc(20, 120).ebike.create(platform_partner: p, vehicle_id: "111")
      bike2_provider1_loc1 = fac.loc(20, 120).ebike.create(platform_partner: p, vehicle_id: "211")
      bike3_provider1_loc2 = fac.loc(40, 140).ebike.create(platform_partner: p, vehicle_id: "312")
      scooter1_provider1_loc1 = fac.loc(20, 120).escooter.create(platform_partner: p, vehicle_id: "s111")
      bike1_provider2_loc1 = fac.loc(20, 120).ebike.create(vehicle_id: "121")

      get "/v1/mobility/map", minloc: [-90, -180], maxloc: [90, 180]

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(
          escooter: [
            {loc: [200_000_000, 1_200_000_000], pi: 0},
          ],
          ebike: [
            {loc: [200_000_000, 1_200_000_000], pi: 0, d: "111"},
            {loc: [200_000_000, 1_200_000_000], pi: 0, d: "211"},
            {loc: [400_000_000, 1_400_000_000], pi: 0},
            {loc: [200_000_000, 1_200_000_000], pi: 1},
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
    let(:prov) { Suma::Fixtures.platform_partner.create }

    it "returns information about the requested vehicle" do
      b1 = fac.loc(0.5, 179.5).ebike.create(platform_partner: prov)
      b2 = fac.loc(30, 120).ebike.create(platform_partner: prov)
      s3 = fac.loc(0.5, 179.5).escooter.create(platform_partner: prov)

      get "/v1/mobility/vehicle", loc: [5_000_000, 1_795_000_000], provider: prov.short_slug, type: "ebike"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(
          :platform_partner,
          vehicle_id: b1.vehicle_id,
          loc: [5_000_000, 1_795_000_000],
        )
    end

    it "can look up a vehicle that must be disambiguated" do
      fac.loc(0.5, 179.5).ebike.create(platform_partner: prov)
      fac.loc(0.5, 179.5).ebike.create(platform_partner: prov, vehicle_id: "abc")

      get "/v1/mobility/vehicle",
          loc: [5_000_000, 1_795_000_000], provider: prov.short_slug, type: "ebike", disambiguator: "abc"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(vehicle_id: "abc")
    end

    it "403s if no vehicle is found" do
      fac.ebike.create(platform_partner: prov)

      get "/v1/mobility/vehicle", loc: [0, 0], provider: prov.short_slug, type: "ebike"

      expect(last_response).to have_status(403)
      expect(last_response).to have_json_body.that_includes(error: include(code: "vehicle_not_found"))
    end

    it "403s if no vehicle with a disambiguator is found" do
      fac.loc(0, 0).ebike.create(platform_partner: prov, vehicle_id: "xyz")
      fac.loc(0, 0).ebike.create(platform_partner: prov, vehicle_id: "abc")

      get "/v1/mobility/vehicle", loc: [0, 0], provider: prov.short_slug, type: "ebike", disambiguator: "rst"

      expect(last_response).to have_status(403)
      expect(last_response).to have_json_body.that_includes(error: include(code: "vehicle_not_found"))
    end

    it "403s if the vehicle must be disambiguated but no disambiguator is passed in" do
      fac.loc(0, 0).ebike.create(platform_partner: prov, vehicle_id: "xyz")
      fac.loc(0, 0).ebike.create(platform_partner: prov, vehicle_id: "abc")

      get "/v1/mobility/vehicle", loc: [0, 0], provider: prov.short_slug, type: "ebike"

      expect(last_response).to have_status(400)
      expect(last_response).to have_json_body.that_includes(error: include(code: "disambiguation_required"))
    end

    it "401s if not logged in" do
      logout
      get "/v1/mobility/vehicle", loc: [0, 0], provider: "a", type: "ebike"
      expect(last_response).to have_status(401)
    end
  end
  #
  # describe "POST /v1/mobility/start_trip" do
  #   it "starts a trip for the customer" do
  #     post "/v1/mobility/start_trip", loc: [45, -122], provider: "spin"
  #
  #     expect(last_response).to have_status(200)
  #     expect(last_response).to have_json_body.
  #       that_includes(x: 1)
  #   end
  # end
end
