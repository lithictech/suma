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

  def format_to_zone(t, tz: "UTC")
    return t.in_time_zone(tz).strftime("%FT%T.%L%:z")
  end

  describe "GET /v1/mobility_trips" do
    it "returns all mobility trips" do
      trip1 = Suma::Fixtures.mobility_trip.create
      trip2 = Suma::Fixtures.mobility_trip.create

      get "/v1/mobility_trips"

      expect(last_response).to have_status(200)
      expect(last_response_json_body[:items].first).to eq(
        {
          admin_link: "http://localhost:22014/mobility-trip/#{trip2.id}",
          began_at: format_to_zone(trip2.began_at),
          created_at: format_to_zone(trip2.created_at),
          ended_at: nil,
          id: trip2.id,
          member: {
            admin_link: "http://localhost:22014/member/#{trip2.member.id}",
            created_at: format_to_zone(trip2.member.created_at),
            email: trip2.member.email,
            id: trip2.member.id,
            name: trip2.member.name,
            phone: trip2.member.phone,
            soft_deleted_at: nil,
            timezone: "America/Los_Angeles",
          },
          total_cost: nil,
          vehicle_id: trip2.vehicle_id,
          vendor_service: {
            admin_link: "http://localhost:22014/vendor-service/#{trip2.vendor_service.id}",
            created_at: format_to_zone(trip2.vendor_service.created_at),
            id: trip2.vendor_service.id,
            name: trip2.vendor_service.external_name,
            vendor: {
              admin_link: "http://localhost:22014/vendor/#{trip2.vendor_service.vendor.id}",
              created_at: format_to_zone(trip2.vendor_service.vendor.created_at),
              id: trip2.vendor_service.vendor.id,
              name: trip2.vendor_service.vendor.name,
            },
          },
        },
      )
      expect(last_response_json_body[:items].last).to eq(
        {
          admin_link: "http://localhost:22014/mobility-trip/#{trip1.id}",
          began_at: format_to_zone(trip1.began_at),
          created_at: format_to_zone(trip1.created_at),
          ended_at: nil,
          id: trip1.id,
          member: {
            admin_link: "http://localhost:22014/member/#{trip1.member.id}",
            created_at: format_to_zone(trip1.member.created_at),
            email: trip1.member.email,
            id: trip1.member.id,
            name: trip1.member.name,
            phone: trip1.member.phone,
            soft_deleted_at: nil,
            timezone: "America/Los_Angeles",
          },
          total_cost: nil,
          vehicle_id: trip1.vehicle_id,
          vendor_service: {
            admin_link: "http://localhost:22014/vendor-service/#{trip1.vendor_service.id}",
            created_at: format_to_zone(trip1.vendor_service.created_at),
            id: trip1.vendor_service.id,
            name: trip1.vendor_service.external_name,
            vendor: {
              admin_link: "http://localhost:22014/vendor/#{trip1.vendor_service.vendor.id}",
              created_at: format_to_zone(trip1.vendor_service.vendor.created_at),
              id: trip1.vendor_service.vendor.id,
              name: trip1.vendor_service.vendor.name,
            },
          },
        },
      )
    end

    it_behaves_like "an endpoint capable of search" do
      let(:url) { "/v1/mobility_trips" }
      let(:search_term) { "abcdefg" }

      def make_matching_items
        return [
          Suma::Fixtures.mobility_trip(external_trip_id: "abcdefg").create,
          Suma::Fixtures.mobility_trip(vehicle_id: "abcdefg").create,
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
      rate = Suma::Fixtures.vendor_service_rate.unit_amount(0).surcharge(0).create
      service = Suma::Fixtures.vendor_service.mobility.create
      charge = Suma::Fixtures.charge(member: admin).create(undiscounted_subtotal_cents: 0)
      begin_lat = -90
      begin_lng = 180
      trip = Suma::Fixtures.mobility_trip.create(
        begin_lat:,
        begin_lng:,
        vendor_service: service,
        vendor_service_rate: rate,
        member: admin,
      )
      trip.charge = charge
      # save_changes does not change the updated_at date
      trip.save # rubocop:disable Sequel/SaveChanges

      get "/v1/mobility_trips/#{trip.id}"

      expect(last_response).to have_status(200)
      expect(last_response_json_body).to eq(
        {
          admin_link: "http://localhost:22014/mobility-trip/#{trip.id}",
          began_at: format_to_zone(trip.began_at),
          begin_lat: "-90.0",
          begin_lng: "180.0",
          charge: {
            admin_link: "http://localhost:22014/charge/#{charge.id}",
            created_at: format_to_zone(charge.created_at),
            discounted_subtotal: {
              cents: 0,
              currency: Suma.default_currency,
            },
            id: charge.id,
            opaque_id: charge.opaque_id,
            undiscounted_subtotal: {
              cents: 0,
              currency: Suma.default_currency,
            },
          },
          created_at: format_to_zone(trip.created_at),
          discount_amount: {
            cents: 0,
            currency: Suma.default_currency,
          },
          ended_at: nil,
          external_links: [],
          external_trip_id: nil,
          id: trip.id,
          member: {
            admin_link: "http://localhost:22014/member/#{admin.id}",
            created_at: format_to_zone(admin.created_at),
            email: admin.email,
            id: admin.id,
            name: admin.name,
            phone: admin.phone,
            soft_deleted_at: nil,
            timezone: "America/Los_Angeles",
          },
          rate: {
            created_at: format_to_zone(rate.created_at),
            id: rate.id,
            name: rate.name,
            surcharge: {
              cents: 0,
              currency: Suma.default_currency,
            },
            undiscounted_amount: nil,
            undiscounted_surcharge: nil,
            unit_amount: {
              cents: 0,
              currency: Suma.default_currency,
            },
            unit_offset: 0,
          },
          total_cost: {
            cents: 0,
            currency: Suma.default_currency,
          },
          updated_at: format_to_zone(trip.refresh.updated_at),
          vehicle_id: trip.vehicle_id,
          vendor_service: {
            admin_link: "http://localhost:22014/vendor-service/#{service.id}",
            created_at: format_to_zone(service.created_at),
            id: service.id,
            name: service.external_name,
            vendor: {
              admin_link: "http://localhost:22014/vendor/#{service.vendor.id}",
              created_at: format_to_zone(service.vendor.created_at),
              id: service.vendor.id,
              name: service.vendor.name,
            },
          },
        },
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
           began_at: "2024-07-01T00:00:00-0700",
           begin_lat: 89.00,
           begin_lng: 180.00

      expect(last_response).to have_status(200)
      expect(last_response_json_body).to eq(
        {
          admin_link: "http://localhost:22014/mobility-trip/#{trip.id}",
          began_at: "2024-07-01T00:00:00.000-07:00",
          begin_lat: "89.0",
          begin_lng: "180.0",
          charge: nil,
          created_at: format_to_zone(trip.created_at),
          discount_amount: nil,
          ended_at: nil,
          external_links: [],
          external_trip_id: nil,
          id: trip.id,
          member: {
            admin_link: "http://localhost:22014/member/#{trip.member.id}",
            created_at: format_to_zone(trip.member.created_at),
            email: trip.member.email,
            id: trip.member.id,
            name: trip.member.name,
            phone: trip.member.phone,
            soft_deleted_at: nil,
            timezone: "America/Los_Angeles",
          },
          rate: {
            created_at: format_to_zone(trip.vendor_service_rate.created_at),
            id: trip.vendor_service_rate.id,
            name: trip.vendor_service_rate.name,
            surcharge: {
              cents: 0,
              currency: Suma.default_currency,
            },
            undiscounted_amount: nil,
            undiscounted_surcharge: nil,
            unit_amount: {
              cents: 0,
              currency: Suma.default_currency,
            },
            unit_offset: 0,
          },
          total_cost: nil,
          # this time is returned with the local timezone
          updated_at: format_to_zone(trip.refresh.updated_at, tz: Time.now.zone),
          vehicle_id: trip.vehicle_id,
          vendor_service: {
            admin_link: "http://localhost:22014/vendor-service/#{trip.vendor_service.id}",
            created_at: format_to_zone(trip.vendor_service.created_at),
            id: trip.vendor_service.id,
            name: trip.vendor_service.external_name,
            vendor: {
              admin_link: "http://localhost:22014/vendor/#{trip.vendor_service.vendor.id}",
              created_at: format_to_zone(trip.vendor_service.vendor.created_at),
              id: trip.vendor_service.vendor.id,
              name: trip.vendor_service.vendor.name,
            },
          },
        },
      )
    end
  end
end
