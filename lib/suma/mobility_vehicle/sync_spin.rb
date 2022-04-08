# frozen_string_literal: true

require "appydays/loggable"
require "suma/http"

module Suma::MobilityVehicle::SyncSpin
  include Appydays::Loggable
  # TODO: Configure this
  GBFS_MARKETS = ["portland"].freeze

  def self.sync_all
    GBFS_MARKETS.each do |m|
      self.sync_gbfs(m)
    end
  end

  def self.sync_gbfs(m)
    (spin = Suma::PlatformPartner[short_slug: "spin"]) or raise "Spin partner does not exist, cannot run this code"
    url = "https://gbfs.spin.pm/api/gbfs/v2_2/#{m}/free_bike_status"
    resp = Suma::Http.get(url, logger: self.logger)
    rows = []
    resp.parsed_response["data"]["bikes"].each do |bike|
      row = {
        lat: bike["lat"],
        lng: bike["lon"],
        vehicle_id: bike["bike_id"],
        vehicle_type: "escooter",
        market: m,
        platform_partner_id: spin.id,
      }
      rows << row
    end
    Suma::MobilityVehicle.db.transaction do
      Suma::MobilityVehicle.where(
        platform_partner: spin,
        market: m,
      ).delete
      Suma::MobilityVehicle.dataset.multi_insert(rows)
    end
  end
end
