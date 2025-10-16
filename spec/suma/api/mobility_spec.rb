# frozen_string_literal: true

require "suma/api/mobility"

require_relative "behaviors"

RSpec.describe Suma::API::Mobility, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:member) { Suma::Fixtures.member.onboarding_verified.with_cash_ledger(amount: money("$15")).create }
  let(:vendor_service_fac) { Suma::Fixtures.vendor_service.mobility_maas.available_to(member) }
  let(:vendor_service) { vendor_service_fac.create }
  let(:program_pricing) { vendor_service.program_pricings.first }
  let(:vehicle_fac) { Suma::Fixtures.mobility_vehicle(vendor_service:) }

  before(:each) do
    login_as(member)
    stub_const("Suma::Mobility::SPIDERIFY_OFFSET_MAGNITUDE", 0.000004)
  end

  describe "GET /v1/mobility/map" do
    it "returns the location of all vehicles within the requested bounds" do
      v1 = vehicle_fac.loc(11, 100).escooter.create
      v2 = vehicle_fac.loc(22, 120).escooter.create
      bike = vehicle_fac.loc(23, 120).ebike.create
      v3 = vehicle_fac.loc(31, 130).escooter.create

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

    it "is limited to vendor services active and available to the user" do
      program = vendor_service.program_pricings.first.program
      program.enrollments.first.destroy

      vehicle_fac.loc(20, 120).escooter.create

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
      vehicle_fac.loc(-0.5, 100).escooter.create

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

    it "includes the usage prohibited reason", reset_configuration: Suma::Payment do
      vehicle_fac.loc(20, 120).create

      get "/v1/mobility/map", sw: [15, 110], ne: [25, 125]
      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        providers: contain_exactly(include(usage_prohibited_reason: nil)),
      )

      Suma::Payment.minimum_cash_balance_for_services_cents = 2000

      get "/v1/mobility/map", sw: [15, 110], ne: [25, 125]
      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        providers: contain_exactly(include(usage_prohibited_reason: "usage_prohibited_cash_balance")),
      )
    end

    it "tells the frontend to refresh in 30 seconds" do
      get "/v1/mobility/map", sw: [-10, 50], ne: [50, 150]

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(refresh: 30_000)
    end

    it "can limit results to the requested type" do
      scooter = vehicle_fac.loc(20, 121).escooter.create
      bike = vehicle_fac.loc(20, 120).ebike.create

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
      v1 = vehicle_fac.loc(20, 120).ebike.create
      vendor_service2 = Suma::Fixtures.vendor_service.available_to(member).create
      v2 = vehicle_fac.loc(20, 120).ebike.create(vendor_service: vendor_service2)
      v3 = vehicle_fac.loc(20, 120).ebike.create(vendor_service: v1.vendor_service)

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
      bike1_provider1_loc1 = vehicle_fac.loc(20, 120).ebike.create(vehicle_id: "111")
      bike2_provider1_loc1 = vehicle_fac.loc(20, 120).ebike.create(vehicle_id: "211")
      bike3_provider1_loc2 = vehicle_fac.loc(40, 140).ebike.create(vehicle_id: "312")
      scooter1_provider1_loc1 = vehicle_fac.loc(20, 120).escooter.create(vehicle_id: "s111")
      provider2 = Suma::Fixtures.vendor_service.available_to(member).create
      bike1_provider2_loc1 = vehicle_fac.loc(20, 120).ebike.create(vehicle_id: "121", vendor_service: provider2)

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
          vehicle_fac.loc(20, 120).escooter.create
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
    it "returns information about the requested vehicle" do
      b1 = vehicle_fac.loc(0.5, 179.5).ebike.create
      b2 = vehicle_fac.loc(30, 120).ebike.create
      s3 = vehicle_fac.loc(0.5, 179.5).escooter.create

      get "/v1/mobility/vehicle", loc: [5_000_000, 1_795_000_000], provider_id: program_pricing.id, type: "ebike"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(
          vendor_service: include(:name, :vendor_name, id: vendor_service.id),
          vehicle_id: b1.vehicle_id,
          loc: [5_000_000, 1_795_000_000],
          rate: include(id: program_pricing.vendor_service_rate_id),
          deeplink: nil,
        )
    end

    it "can look up a vehicle that must be disambiguated" do
      vehicle_fac.loc(0.5, 179.5).ebike.create
      vehicle_fac.loc(0.5, 179.5).ebike.create(vehicle_id: "abc")

      get "/v1/mobility/vehicle",
          loc: [5_000_000, 1_795_000_000], provider_id: program_pricing.id, type: "ebike", disambiguator: "abc"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(vehicle_id: "abc")
    end

    it "returns a service-specific prohibited reason" do
      program_pricing.vendor_service_rate.update(surcharge: money("$5"))

      vehicle_fac.loc(0.5, 179.5).ebike.create

      get "/v1/mobility/vehicle",
          loc: [5_000_000, 1_795_000_000], provider_id: program_pricing.id, type: "ebike"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(usage_prohibited_reason: "usage_prohibited_instrument_required")
    end

    it "403s if no vehicle is found" do
      vehicle_fac.ebike.create

      get "/v1/mobility/vehicle", loc: [0, 0], provider_id: program_pricing.id, type: "ebike"

      expect(last_response).to have_status(403)
      expect(last_response).to have_json_body.that_includes(error: include(code: "vehicle_not_found"))
    end

    it "403s if the vehicle is not available within the given provider" do
      b1 = vehicle_fac.loc(0, 0).ebike.create(vendor_service: vendor_service_fac.create)

      get "/v1/mobility/vehicle", loc: [0, 0], provider_id: program_pricing.id, type: "ebike"

      expect(last_response).to have_status(403)
    end

    it "403s if the provider is not evailable to the member" do
      pp2 = Suma::Fixtures.program_pricing.create
      b1 = vehicle_fac.loc(0, 0).ebike.create(vendor_service: pp2.vendor_service)

      get "/v1/mobility/vehicle", loc: [0, 0], provider_id: pp2.id, type: "ebike"

      expect(last_response).to have_status(403)
    end

    it "403s if no vehicle with a disambiguator is found" do
      vehicle_fac.loc(0, 0).ebike.create(vehicle_id: "xyz")
      vehicle_fac.loc(0, 0).ebike.create(vehicle_id: "abc")

      get "/v1/mobility/vehicle", loc: [0, 0], provider_id: program_pricing.id, type: "ebike", disambiguator: "rst"

      expect(last_response).to have_status(403)
      expect(last_response).to have_json_body.that_includes(error: include(code: "vehicle_not_found"))
    end

    it "403s if the vehicle must be disambiguated but no disambiguator is passed in" do
      vehicle_fac.loc(0, 0).ebike.create(vehicle_id: "xyz")
      vehicle_fac.loc(0, 0).ebike.create(vehicle_id: "abc")

      get "/v1/mobility/vehicle", loc: [0, 0], provider_id: program_pricing.id, type: "ebike"

      expect(last_response).to have_status(400)
      expect(last_response).to have_json_body.that_includes(error: include(code: "disambiguation_required"))
    end

    it "401s if not logged in" do
      logout
      get "/v1/mobility/vehicle", loc: [0, 0], provider_id: 0, type: "ebike"
      expect(last_response).to have_status(401)
    end

    it "provides deeplink information if adapter uses it" do
      b1 = vehicle_fac.loc(0.5, 179.5).ebike.create(vehicle_id: "abcd")
      b1.vendor_service.mobility_adapter.update(uses_deep_linking: true, trip_provider_key: "")

      get "/v1/mobility/vehicle", loc: [5_000_000, 1_795_000_000], provider_id: program_pricing.id, type: "ebike"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(
          vehicle_id: b1.vehicle_id,
          deeplink: "http://localhost:22004/error",
        )
    end
  end

  describe "POST /v1/mobility/begin_trip" do
    let(:vehicle) { Suma::Fixtures.mobility_vehicle.create(vendor_service:) }

    it "starts a trip for the resident using the given vehicle and its associated rate" do
      post "/v1/mobility/begin_trip", provider_id: program_pricing.id, vehicle_id: vehicle.vehicle_id

      expect(last_response).to have_status(200)
      expect(last_response.headers).to include("Suma-Current-Member")
      expect(last_response).to have_json_body.that_includes(:id)

      trip = Suma::Mobility::Trip[last_response_json_body[:id]]
      expect(trip).to have_attributes(member: be === member)
    end

    it "errors if the vehicle cannot be found" do
      post "/v1/mobility/begin_trip", provider_id: program_pricing.id, vehicle_id: vehicle.vehicle_id + "1"

      expect(last_response).to have_status(403)
      expect(last_response).to have_json_body.that_includes(error: include(code: "vehicle_not_found"))
    end

    it "errors if the resident already has an active trip" do
      Suma::Fixtures.mobility_trip.ongoing.for_vehicle(vehicle).create(member:)

      post "/v1/mobility/begin_trip", provider_id: program_pricing.id, vehicle_id: vehicle.vehicle_id

      expect(last_response).to have_status(409)
      expect(last_response).to have_json_body.that_includes(error: include(code: "ongoing_trip"))
    end

    it "errors if the member cannot access the service due to eligibility" do
      program_pricing.program.enrollments.first.destroy

      post "/v1/mobility/begin_trip", provider_id: program_pricing.id, vehicle_id: vehicle.vehicle_id

      expect(last_response).to have_status(403)
      expect(last_response).to have_json_body.that_includes(error: include(code: "vehicle_not_found"))
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
            end_index: 3,
          },
          {
            begin_at: "2024-09-30",
            end_at: "2024-10-06",
            begin_index: 3,
            end_index: 4,
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
