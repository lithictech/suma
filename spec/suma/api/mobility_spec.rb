# frozen_string_literal: true

require "suma/api/mobility"

require_relative "behaviors"

RSpec.describe Suma::API::Mobility, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:member) { Suma::Fixtures.member.onboarding_verified.with_cash_ledger(amount: money("$15")).create }

  before(:each) do
    login_as(member)
    stub_const("Suma::Mobility::SPIDERIFY_OFFSET_MAGNITUDE", 0.000004)
    Suma::Mobility::VendorAdapter::Fake.reset
  end

  describe "GET /v1/mobility/map" do
    it "returns the location of all vehicles within the requested bounds" do
      fac = Suma::Fixtures.mobility_vehicle(vendor_service: Suma::Fixtures.vendor_service.mobility.create)
      v1 = fac.loc(11, 100).escooter.create
      v2 = fac.loc(22, 120).escooter.create
      bike = fac.loc(23, 120).ebike.create
      v3 = fac.loc(31, 130).escooter.create

      get "/v1/mobility/map", sw: [15, 110], ne: [25, 125]

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(
          escooter: [
            {c: [220_000_000, 1_200_000_000], p: 0},
          ],
          ebike: [
            {c: [230_000_000, 1_200_000_000], p: 0},
          ],
        )
    end

    it "is limited to vendor mobility services" do
      fac = Suma::Fixtures.mobility_vehicle(vendor_service: Suma::Fixtures.vendor_service.food.create)
      fac.loc(20, 120).escooter.create

      get "/v1/mobility/map", sw: [15, 110], ne: [25, 125]

      expect(last_response).to have_status(200)
      expect(last_response_json_body).to_not include(:escooter, :ebike)
    end

    it "is limited to vendor services active and available to the user" do
      program = Suma::Fixtures.program.create
      vendor_service = Suma::Fixtures.vendor_service.mobility.with_programs(program).create

      Suma::Fixtures.mobility_vehicle(vendor_service:).
        loc(20, 120).
        escooter.
        create

      get "/v1/mobility/map", sw: [15, 110], ne: [25, 125]

      expect(last_response).to have_status(200)
      expect(last_response_json_body).to_not include(:escooter, :ebike)

      Suma::Fixtures.program_enrollment.create(program:, member:)
      get "/v1/mobility/map", sw: [15, 110], ne: [25, 125]

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(escooter: have_length(1))

      vendor_service.update(period_end: 2.days.ago)
      get "/v1/mobility/map", sw: [15, 110], ne: [25, 125]

      expect(last_response).to have_status(200)
      expect(last_response_json_body).to_not include(:escooter, :ebike)
    end

    it "handles coordinate precision" do
      Suma::Fixtures.mobility_vehicle.loc(-0.5, 100).escooter.create

      get "/v1/mobility/map", sw: [-10, 50], ne: [50, 150]

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

    it "indicates if the service allows zero-balance rides" do
      vendor_service = Suma::Fixtures.vendor_service.mobility.create
      Suma::Fixtures.mobility_vehicle(vendor_service:).loc(20, 120).create

      get "/v1/mobility/map", sw: [15, 110], ne: [25, 125]
      expect(last_response).to have_status(200)
      expect(last_response_json_body).to include(providers: contain_exactly(include(zero_balance_ok: false)))

      vendor_service.update(charge_after_fulfillment: true)

      get "/v1/mobility/map", sw: [15, 110], ne: [25, 125]
      expect(last_response).to have_status(200)
      expect(last_response_json_body).to include(providers: contain_exactly(include(zero_balance_ok: true)))
    end

    it "tells the frontend to refresh in 30 seconds" do
      get "/v1/mobility/map", sw: [-10, 50], ne: [50, 150]

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(refresh: 30_000)
    end

    it "can limit results to the requested type" do
      fac = Suma::Fixtures.mobility_vehicle(vendor_service: Suma::Fixtures.vendor_service.mobility.create)
      scooter = fac.loc(20, 121).escooter.create
      bike = fac.loc(20, 120).ebike.create

      get "/v1/mobility/map", sw: [15, 110], ne: [25, 125], types: ["ebike"]

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

      get "/v1/mobility/map", sw: [15, 110], ne: [25, 125]

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

    it "disambiguates and offsets vehicles of the same type and provider at the same location" do
      vs = Suma::Fixtures.vendor_service.mobility.create
      fac = Suma::Fixtures.mobility_vehicle
      bike1_provider1_loc1 = fac.loc(20, 120).ebike.create(vendor_service: vs, vehicle_id: "111")
      bike2_provider1_loc1 = fac.loc(20, 120).ebike.create(vendor_service: vs, vehicle_id: "211")
      bike3_provider1_loc2 = fac.loc(40, 140).ebike.create(vendor_service: vs, vehicle_id: "312")
      scooter1_provider1_loc1 = fac.loc(20, 120).escooter.create(vendor_service: vs, vehicle_id: "s111")
      bike1_provider2_loc1 = fac.loc(20, 120).ebike.create(vehicle_id: "121")

      get "/v1/mobility/map", sw: [-90, -180], ne: [90, 180]

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(
          escooter: [
            {c: [200_000_000, 1_200_000_000], p: 0, o: [28, -28]},
          ],
          ebike: [
            {c: [200_000_000, 1_200_000_000], p: 0, d: "111", o: [28, 28]},
            {c: [200_000_000, 1_200_000_000], p: 0, d: "211", o: [-28, 28]},
            {c: [400_000_000, 1_400_000_000], p: 0},
            {c: [200_000_000, 1_200_000_000], p: 1, o: [-28, -28]},
          ],
        )
    end

    context "when offsetting vehicles at the same location" do
      def get_same_location_vehicles(amount)
        amount.times do
          Suma::Fixtures.mobility_vehicle.loc(20, 120).escooter.create
        end
        get "/v1/mobility/map", sw: [15, 110], ne: [25, 125]
      end

      it "offsets 2 vehicles" do
        get_same_location_vehicles(2)
        expect(last_response).to have_status(200)
        expect(last_response).to have_json_body.
          that_includes(
            escooter: contain_exactly(
              include(o: [0, 40]),
              include(o: [0, -40]),
            ),
          )
      end

      it "offsets 4 vehicles" do
        get_same_location_vehicles(4)
        expect(last_response).to have_status(200)
        expect(last_response).to have_json_body.
          that_includes(
            escooter: contain_exactly(
              include(o: [28, 28]),
              include(o: [-28, 28]),
              include(o: [-28, -28]),
              include(o: [28, -28]),
            ),
          )
      end

      it "offsets 5 vehicles" do
        get_same_location_vehicles(5)
        expect(last_response).to have_status(200)
        expect(last_response).to have_json_body.
          that_includes(
            escooter: contain_exactly(
              include(o: [32, 24]),
              include(o: [-12, 38]),
              include(o: [-40, 0]),
              include(o: [-12, -38]),
              include(o: [32, -24]),
            ),
          )
      end
    end

    it "401s if not logged in" do
      logout
      get "/v1/mobility/map", sw: [15, 110], ne: [25, 125]
      expect(last_response).to have_status(401)
    end
  end

  describe "GET /v1/mobility/map_features" do
    it "returns the location of restricted areas within the given bounds" do
      ra1 = Suma::Fixtures.mobility_restricted_area.
        latlng_bounds(sw: [20, 120], ne: [50, 150]).
        create(restriction: "do-not-park-or-ride")
      ra2 = Suma::Fixtures.mobility_restricted_area.
        latlng_bounds(sw: [30, 130], ne: [50, 150]).
        create(restriction: "do-not-park")

      get "/v1/mobility/map_features", sw: [15, 110], ne: [25, 125]

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(
          restrictions: [
            {
              restriction: "do-not-park-or-ride",
              multipolygon: [
                [
                  [
                    [20.0, 120.0],
                    [50.0, 120.0],
                    [50.0, 150.0],
                    [20.0, 150.0],
                    [20.0, 120.0],
                  ],
                ],
              ],
              bounds: {
                ne: [50.0, 150.0],
                sw: [20.0, 120.0],
              },
            },
          ],
        )
    end

    it "401s if not logged in" do
      logout
      get "/v1/mobility/map_features", sw: [15, 110], ne: [25, 125]
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
          deeplink: nil,
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

    it "provides deeplink information if adapter uses it" do
      Suma::Mobility::VendorAdapter::Fake.uses_deep_linking = true

      b1 = fac.loc(0.5, 179.5).ebike.create(vendor_service: vsvc, vehicle_id: "abcd")

      get "/v1/mobility/vehicle", loc: [5_000_000, 1_795_000_000], provider_id: vsvc.id, type: "ebike"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(
          vehicle_id: b1.vehicle_id,
          deeplink: "http://localhost:22004/error",
        )
    end
  end

  describe "POST /v1/mobility/begin_trip" do
    let(:vendor_service) { Suma::Fixtures.vendor_service.mobility.create }
    let(:vehicle) { Suma::Fixtures.mobility_vehicle.create(vendor_service:) }
    let(:rate) { Suma::Fixtures.vendor_service_rate.for_service(vendor_service).create }

    it "starts a trip for the resident using the given vehicle and its associated rate" do
      post "/v1/mobility/begin_trip",
           provider_id: vehicle.vendor_service_id, vehicle_id: vehicle.vehicle_id, rate_id: rate.id

      expect(last_response).to have_status(200)
      expect(last_response.headers).to include("Suma-Current-Member")
      expect(last_response).to have_json_body.that_includes(:id)

      trip = Suma::Mobility::Trip[last_response_json_body[:id]]
      expect(trip).to have_attributes(member: be === member)
    end

    it "errors if the vehicle cannot be found" do
      post "/v1/mobility/begin_trip",
           provider_id: vehicle.vendor_service_id, vehicle_id: vehicle.vehicle_id + "1", rate_id: rate.id

      expect(last_response).to have_status(403)
      expect(last_response).to have_json_body.that_includes(error: include(code: "vehicle_not_found"))
    end

    it "errors if the resident already has an active trip" do
      Suma::Fixtures.mobility_trip.ongoing.for_vehicle(vehicle).create(member:)

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

    it "errors if the member cannot access the service due to eligibility" do
      vendor_service.add_program(Suma::Fixtures.program.create)

      post "/v1/mobility/begin_trip",
           provider_id: vehicle.vendor_service_id, vehicle_id: vehicle.vehicle_id, rate_id: rate.id

      expect(last_response).to have_status(403)
      expect(last_response).to have_json_body.that_includes(error: include(code: "eligibility_violation"))
    end
  end

  describe "POST /v1/mobility/end_trip" do
    let!(:member_ledger) { Suma::Fixtures.ledger.member(member).category(:mobility).create }

    it "ends the active trip for the resident" do
      trip = Suma::Fixtures.mobility_trip.ongoing.create(member:)
      expect(trip).to_not be_ended

      post "/v1/mobility/end_trip", lat: 5, lng: -5

      expect(last_response).to have_status(200)
      expect(last_response.headers).to include("Suma-Current-Member")
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
        create(began_at: 6.minutes.ago, vendor_service_rate: rate, member:)

      post "/v1/mobility/end_trip", lat: 5, lng: -5

      expect(last_response).to have_status(200)
      expect(trip.charge).to have_attributes(
        undiscounted_subtotal: cost("$1.62"),
        discounted_subtotal: cost("$1.20"),
      )
    end
  end

  describe "GET /v1/mobility/trips" do
    let!(:member_ledger) { Suma::Fixtures.ledger.member(member).category(:mobility).create }

    it "returns trips grouped by week" do
      _ = Suma::Fixtures.mobility_trip.create
      fac = Suma::Fixtures.mobility_trip(member:).ended
      t1 = fac.create(began_at: Time.parse("2025-02-17T12:00:00Z"))
      t2 = fac.create(began_at: Time.parse("2025-02-19T12:00:00Z"))
      ongoing = fac.ongoing.create(began_at: Time.parse("2025-02-17T12:00:00Z"))
      t3 = fac.create(began_at: Time.parse("2025-02-18T12:00:00Z"))
      t4 = fac.create(began_at: Time.parse("2024-09-30T12:00:00Z"))

      get "/v1/mobility/trips"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        items: have_same_ids_as(t2, t3, t1, t4).ordered,
        ongoing: include(id: ongoing.id),
        weeks: [
          {
            begin_at: "2025-02-17",
            end_at: "2025-02-23",
            begin_index: 0,
            end_index: 2,
          },
          {
            begin_at: "2024-09-30",
            end_at: "2024-10-06",
            begin_index: 3,
            end_index: 3,
          },
        ],
      )
    end

    it_behaves_like "an endpoint with pagination", download: false do
      let(:url) { "/v1/mobility/trips" }
      def make_item(i)
        return Suma::Fixtures.mobility_trip.ended.create(member:, began_at: Time.now - i.days)
      end
    end
  end
end
