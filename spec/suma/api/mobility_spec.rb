# frozen_string_literal: true

require "suma/api/mobility"

RSpec.describe Suma::API::Mobility, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:member) { Suma::Fixtures.customer.onboarding_verified.with_cash_ledger(amount: money("$15")).create }

  before(:each) do
    login_as(customer)
  end

  describe "GET /v1/mobility/map" do
    it "returns the location of all vehicles within the requested bounds" do
      fac = Suma::Fixtures.mobility_vehicle(vendor_service: Suma::Fixtures.vendor_service.mobility.create)
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

    it "is limited to vendor mobility services" do
      fac = Suma::Fixtures.mobility_vehicle(vendor_service: Suma::Fixtures.vendor_service.food.create)
      fac.loc(20, 120).escooter.create

      get "/v1/mobility/map", minloc: [15, 110], maxloc: [25, 125]

      expect(last_response).to have_status(200)
      expect(last_response_json_body).to_not include(:escooter, :ebike)
    end

    it "is limited to vendor services available to the user" do
      # TODO: Requires constraint implementation
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
      fac = Suma::Fixtures.mobility_vehicle(vendor_service: Suma::Fixtures.vendor_service.mobility.create)
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
      v2 = Suma::Fixtures.mobility_vehicle.loc(20, 120).ebike.create(vendor_service: v1.vendor_service)

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
      vs = Suma::Fixtures.vendor_service.mobility.create
      fac = Suma::Fixtures.mobility_vehicle
      bike1_provider1_loc1 = fac.loc(20, 120).ebike.create(vendor_service: vs, vehicle_id: "111")
      bike2_provider1_loc1 = fac.loc(20, 120).ebike.create(vendor_service: vs, vehicle_id: "211")
      bike3_provider1_loc2 = fac.loc(40, 140).ebike.create(vendor_service: vs, vehicle_id: "312")
      scooter1_provider1_loc1 = fac.loc(20, 120).escooter.create(vendor_service: vs, vehicle_id: "s111")
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
    let(:vsvc) { Suma::Fixtures.vendor_service.mobility.create }
    let!(:rate) { Suma::Fixtures.vendor_service_rate.for_service(vsvc).create }

    it "returns information about the requested vehicle" do
      b1 = fac.loc(0.5, 179.5).ebike.create(vendor_service: vsvc)
      b2 = fac.loc(30, 120).ebike.create(vendor_service: vsvc)
      s3 = fac.loc(0.5, 179.5).escooter.create(vendor_service: vsvc)

      get "/v1/mobility/vehicle", loc: [5_000_000, 1_795_000_000], provider_id: vsvc.id, type: "ebike"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(
          vendor_service: include(:name, :vendor_name, id: vsvc.id),
          vehicle_id: b1.vehicle_id,
          loc: [5_000_000, 1_795_000_000],
          rate: include(id: rate.id),
        )
    end

    it "can look up a vehicle that must be disambiguated" do
      fac.loc(0.5, 179.5).ebike.create(vendor_service: vsvc)
      fac.loc(0.5, 179.5).ebike.create(vendor_service: vsvc, vehicle_id: "abc")

      get "/v1/mobility/vehicle",
          loc: [5_000_000, 1_795_000_000], provider_id: vsvc.id, type: "ebike", disambiguator: "abc"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(vehicle_id: "abc")
    end

    it "403s if no vehicle is found" do
      fac.ebike.create(vendor_service: vsvc)

      get "/v1/mobility/vehicle", loc: [0, 0], provider_id: vsvc.id, type: "ebike"

      expect(last_response).to have_status(403)
      expect(last_response).to have_json_body.that_includes(error: include(code: "vehicle_not_found"))
    end

    it "403s if no vehicle with a disambiguator is found" do
      fac.loc(0, 0).ebike.create(vendor_service: vsvc, vehicle_id: "xyz")
      fac.loc(0, 0).ebike.create(vendor_service: vsvc, vehicle_id: "abc")

      get "/v1/mobility/vehicle", loc: [0, 0], provider_id: vsvc.id, type: "ebike", disambiguator: "rst"

      expect(last_response).to have_status(403)
      expect(last_response).to have_json_body.that_includes(error: include(code: "vehicle_not_found"))
    end

    it "403s if the vehicle must be disambiguated but no disambiguator is passed in" do
      fac.loc(0, 0).ebike.create(vendor_service: vsvc, vehicle_id: "xyz")
      fac.loc(0, 0).ebike.create(vendor_service: vsvc, vehicle_id: "abc")

      get "/v1/mobility/vehicle", loc: [0, 0], provider_id: vsvc.id, type: "ebike"

      expect(last_response).to have_status(400)
      expect(last_response).to have_json_body.that_includes(error: include(code: "disambiguation_required"))
    end

    it "401s if not logged in" do
      logout
      get "/v1/mobility/vehicle", loc: [0, 0], provider_id: 0, type: "ebike"
      expect(last_response).to have_status(401)
    end
  end

  describe "POST /v1/mobility/begin_trip" do
    let(:vendor_service) { Suma::Fixtures.vendor_service.create }
    let(:vehicle) { Suma::Fixtures.mobility_vehicle.create(vendor_service:) }
    let(:rate) { Suma::Fixtures.vendor_service_rate.for_service(vendor_service).create }

    it "starts a trip for the resident using the given vehicle and its associated rate" do
      post "/v1/mobility/begin_trip",
           provider_id: vehicle.vendor_service_id, vehicle_id: vehicle.vehicle_id, rate_id: rate.id

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(:id)

      trip = Suma::Mobility::Trip[last_response_json_body[:id]]
      expect(trip).to have_attributes(customer: be === customer)
    end

    it "errors if the vehicle cannot be found" do
      post "/v1/mobility/begin_trip",
           provider_id: vehicle.vendor_service_id, vehicle_id: vehicle.vehicle_id + "1", rate_id: rate.id

      expect(last_response).to have_status(403)
      expect(last_response).to have_json_body.that_includes(error: include(code: "vehicle_not_found"))
    end

    it "errors if the resident already has an active trip" do
      Suma::Fixtures.mobility_trip.ongoing.for_vehicle(vehicle).create(customer:)

      post "/v1/mobility/begin_trip",
           provider_id: vehicle.vendor_service_id, vehicle_id: vehicle.vehicle_id, rate_id: rate.id

      expect(last_response).to have_status(409)
      expect(last_response).to have_json_body.that_includes(error: include(code: "ongoing_trip"))
    end

    it "errors if the given rate does not exist for the provider" do
      rate2 = Suma::Fixtures.vendor_service_rate.create
      post "/v1/mobility/begin_trip",
           provider_id: vehicle.vendor_service_id, vehicle_id: vehicle.vehicle_id, rate_id: rate2.id

      expect(last_response).to have_status(403)
      expect(last_response).to have_json_body.that_includes(error: include(code: "rate_not_found"))
    end
  end

  describe "POST /v1/mobility/end_trip" do
    let!(:member_ledger) { Suma::Fixtures.ledger.customer(customer).category(:mobility).create }

    it "ends the active trip for the resident" do
      trip = Suma::Fixtures.mobility_trip.ongoing.create(customer:)
      expect(trip).to_not be_ended

      post "/v1/mobility/end_trip", lat: 5, lng: -5

      expect(last_response).to have_status(200)
      expect(trip.refresh).to be_ended
      expect(trip).to have_attributes(end_lat: 5, end_lng: -5)
    end

    it "errors if the resident has no active trip" do
      post "/v1/mobility/end_trip", lat: 5, lng: -5

      expect(last_response).to have_status(409)
      expect(last_response).to have_json_body.that_includes(error: include(code: "no_active_trip"))
    end

    it "creates a charge using the rate attached to the trip" do
      rate = Suma::Fixtures.vendor_service_rate.
        unit_amount(20).
        discounted_by(0.25).
        create
      trip = Suma::Fixtures.mobility_trip.
        ongoing.
        create(began_at: 6.minutes.ago, vendor_service_rate: rate, customer:)

      post "/v1/mobility/end_trip", lat: 5, lng: -5

      expect(last_response).to have_status(200)
      expect(trip.charge).to have_attributes(
        undiscounted_subtotal: cost("$1.62"),
        discounted_subtotal: cost("$1.20"),
      )
    end
  end
end
