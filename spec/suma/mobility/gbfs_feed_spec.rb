# frozen_string_literal: true

RSpec.describe "Suma::Mobility::GbfsFeed", :db do
  let(:described_class) { Suma::Mobility::GbfsFeed }
  let(:now) { Time.now }

  it "can be fixtured" do
    expect(Suma::Fixtures.mobility_gbfs_feed.create).to be_a(described_class)
  end

  describe "datasets" do
    describe "ready_to_sync" do
      it "returns rows with enabled components that have not been synced recently" do
        feed = Suma::Fixtures.mobility_gbfs_feed.create(free_bike_status_enabled: true)

        expect(described_class.ready_to_sync(:free_bike_status, now:).all).to have_same_ids_as(feed)
        expect(described_class.ready_to_sync(:geofencing_zones, now:).all).to be_empty

        feed.update(free_bike_status_synced_at: now)
        expect(described_class.ready_to_sync(:free_bike_status, now:).all).to be_empty
        expect(described_class.ready_to_sync(:free_bike_status, now: 80.seconds.from_now).all).to have_same_ids_as(feed)
      end
    end
  end

  describe "sync_component" do
    let(:vendor_service) { Suma::Fixtures.vendor_service.mobility_deeplink.create }
    let(:vendor) { vendor_service.vendor }

    it "syncs" do
      geofencing_zone_req = stub_request(:get, "https://fake.mysuma.org/geofencing_zones.json").
        to_return(fixture_response("lime/geofencing_zone"))
      vehicle_types_req = stub_request(:get, "https://fake.mysuma.org/vehicle_types.json").
        to_return(fixture_response("lime/vehicle_types"))

      feed = Suma::Fixtures.mobility_gbfs_feed.create(vendor:, feed_root_url: "https://fake.mysuma.org")
      feed.sync_component("geofencing_zones")
      expect(geofencing_zone_req).to have_been_made
      expect(vehicle_types_req).to have_been_made
      expect(Suma::Mobility::RestrictedArea.all).to have_length(1)
    end
  end
end
