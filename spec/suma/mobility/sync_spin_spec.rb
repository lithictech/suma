# frozen_string_literal: true

require "suma/mobility/sync_spin"

RSpec.describe "Suma::Mobility::SyncSpin", :db do
  let(:described_class) { Suma::Mobility::SyncSpin }

  describe "sync_all" do
    it "syncs all " do
      stub_request(:get, "https://gbfs.spin.pm/api/gbfs/v2_2/portland/free_bike_status").
        to_return(**fixture_response("spin/gbfs_portland.json"))
      stub_request(:get, "https://gbfs.spin.pm/api/gbfs/v2_2/mexicocity/scooters").
        to_return(**fixture_response("spin/gbfs_portland.json"))

      fac = Suma::Fixtures.vendor_service(vendor: Suma::Fixtures.vendor(name: "Spin").create).mobility
      vs1 = fac.create(sync_url: "https://gbfs.spin.pm/api/gbfs/v2_2/portland/free_bike_status")
      vs2 = fac.create(sync_url: "https://gbfs.spin.pm/api/gbfs/v2_2/mexicocity/scooters")
      i = described_class.sync_all
      expect(Suma::Mobility::Vehicle.all).to have_length(4)
      expect(i).to eq(4)
    end
  end
end
