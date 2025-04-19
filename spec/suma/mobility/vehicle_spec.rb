# frozen_string_literal: true

RSpec.describe "Suma::Mobility::Vehicle", :db do
  let(:described_class) { Suma::Mobility::Vehicle }

  before(:each) do
    Suma::Mobility::VendorAdapter::Fake.reset
  end

  it "can be fixtured" do
    expect(Suma::Fixtures.mobility_vehicle.create).to be_a(described_class)
  end

  describe "search" do
    it "can find all vehicles in the given bounds" do
      v1 = Suma::Fixtures.mobility_vehicle.loc(10, 100).create
      v2 = Suma::Fixtures.mobility_vehicle.loc(20, 120).create
      v3 = Suma::Fixtures.mobility_vehicle.loc(30, 130).create
      v4 = Suma::Fixtures.mobility_vehicle.loc(40, 140).create

      results = described_class.search(min_lat: 15, max_lat: 35, min_lng: 115, max_lng: 125)
      expect(results.all).to contain_exactly(v2)
    end
  end

  describe "deep_link_for_user_agent" do
    let(:v) { Suma::Fixtures.mobility_vehicle.create }

    # rubocop:disable Layout/LineLength
    android_ua = "Mozilla/5.0 (Linux; Android 8.1.0; S10_Pro Build/O11019; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/114.0.5735.131 Mobile Safari/537.36"
    ios_ua = "Mozilla/5.0 (iPhone; CPU iPhone OS 16_5_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 it.fanpage.rn.ios/3.10.9"
    desktop_ua = "Mozilla/3.0 (Windows NT 6.3; WOW64; rv:61.0) Gecko/20100601 Firefox/61.0"
    # rubocop:enable Layout/LineLength

    it "is nil if the adapter does not use deep linking" do
      v.rental_uris = {"android" => "playstore", "ios" => "appstore"}
      expect(v.deep_link_for_user_agent(android_ua)).to be_nil
    end

    it "uses the appropriate platform" do
      Suma::Mobility::VendorAdapter::Fake.uses_deep_linking = true
      v.rental_uris = {"android" => "playstore", "ios" => "appstore"}
      expect(v.deep_link_for_user_agent(android_ua)).to eq("playstore")
      expect(v.deep_link_for_user_agent(ios_ua)).to eq("appstore")
    end

    it "falls back to web if available, android if not, and finally ios" do
      Suma::Mobility::VendorAdapter::Fake.uses_deep_linking = true
      v.rental_uris = {"android" => "playstore", "ios" => "appstore", "web" => "open"}
      expect(v.deep_link_for_user_agent(desktop_ua)).to eq("open")
      expect(v.deep_link_for_user_agent(nil)).to eq("open")
      expect(v.deep_link_for_user_agent("")).to eq("open")
      v.rental_uris.delete("web")
      expect(v.deep_link_for_user_agent(desktop_ua)).to eq("playstore")
      v.rental_uris.delete("android")
      expect(v.deep_link_for_user_agent(desktop_ua)).to eq("appstore")
      v.rental_uris.delete("ios")
      expect(Sentry).to receive(:capture_message)
      expect(v.deep_link_for_user_agent(desktop_ua)).to eq("http://localhost:22004/error")
    end

    it "uses Biketown urls if the vendor is Biketown and the vehicle is an ebike" do
      Suma::Mobility::VendorAdapter::Fake.uses_deep_linking = true
      v.vehicle_type = "ebike"
      canonical = "https://www.biketownpdx.com/lastmile_qr_scan"
      v.rental_uris = {"android" => canonical}
      expect(v.deep_link_for_user_agent(android_ua)).to eq(canonical)
      v.rental_uris = {"android" => "https://biketownpdx.com/lastmile_qr_scan"}
      expect(v.deep_link_for_user_agent(android_ua)).to eq(canonical)
      v.rental_uris = {"android" => "https://pdx.lft.to/lastmile_qr_scan"}
      expect(v.deep_link_for_user_agent(android_ua)).to eq(canonical)
      v.rental_uris = {"android" => "https://lyft.biketownpdx.com/lastmile_qr_scan"}
      expect(v.deep_link_for_user_agent(android_ua)).to eq(canonical)

      v.vehicle_type = "escooter"
      v.rental_uris = {"android" => "https://lyft.biketownpdx.com/lastmile_qr_scan"}
      expect(v.deep_link_for_user_agent(android_ua)).to eq("https://lyft.biketownpdx.com/lastmile_qr_scan")
    end
  end
end
