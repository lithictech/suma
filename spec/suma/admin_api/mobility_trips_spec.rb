# frozen_string_literal: true

require "suma/admin_api/mobility_trips"
require "suma/api/behaviors"

RSpec.describe Suma::AdminAPI::MobilityTrips, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create }

  before(:each) do
    login_as(admin)
  end

  describe "GET /v1/mobility_trips" do
    it "returns all mobility trips" do
      objs = Array.new(2) { Suma::Fixtures.mobility_trip.create }

      get "/v1/mobility_trips"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(items: have_same_ids_as(*objs))
    end

    it_behaves_like "an endpoint capable of search" do
      let(:url) { "/v1/mobility_trips" }
      let(:search_term) { "zzz" }

      def make_matching_items
        return [
          Suma::Fixtures.mobility_trip(external_trip_id: "zzz").create,
          Suma::Fixtures.mobility_trip(vehicle_id: "zzz").create,
        ]
      end

      def make_non_matching_items
        return [
          Suma::Fixtures.mobility_trip(external_trip_id: translated_text("wibble wobble")).create,
        ]
      end
    end

    it_behaves_like "an endpoint with pagination" do
      let(:url) { "/v1/mobility_trips" }
      def make_item(i)
        # Sorting is newest first, so the first items we create need to the the oldest.
        created = Time.now - i.days
        return Suma::Fixtures.mobility_trip.create(created_at: created)
      end
    end

    it_behaves_like "an endpoint with member-supplied ordering" do
      let(:url) { "/v1/mobility_trips" }
      let(:order_by_field) { "id" }
      def make_item(_i)
        return Suma::Fixtures.mobility_trip.create(
          created_at: Time.now + rand(1..100).days,
        )
      end
    end
  end

  describe "GET /v1/mobility_trips/:id" do
    it "returns the mobility trip" do
      rate = Suma::Fixtures.vendor_service_rate.create
      service = Suma::Fixtures.vendor_service.mobility_deeplink.create
      charge = Suma::Fixtures.charge(member: admin).create
      trip = Suma::Fixtures.mobility_trip.create(vendor_service: service, vendor_service_rate: rate, member: admin)
      trip.charge = charge
      trip.save_changes

      get "/v1/mobility_trips/#{trip.refresh.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        id: trip.id,
        vendor_service: include(id: service.id),
        rate: include(id: rate.id),
        member: include(id: admin.id),
        charge: include(id: charge.id),
      )
    end

    it "403s if the item does not exist" do
      get "/v1/mobility_trips/0"

      expect(last_response).to have_status(403)
    end
  end

  describe "POST /v1/mobility_trips/:id" do
    it "updates a mobility trip" do
      trip = Suma::Fixtures.mobility_trip.create

      post "/v1/mobility_trips/#{trip.id}",
           begin_lat: 1,
           begin_lng: 1,
           end_lat: 2,
           end_lng: 2,
           began_at: "2024-07-01T00:00:00-0700",
           ended_at: "2024-07-01T00:00:00-0700"

      expect(last_response).to have_status(200)
      expect(trip.refresh).to have_attributes(begin_lat: 1, end_lat: 2)
    end
  end
end
