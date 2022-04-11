# frozen_string_literal: true

require "appydays/loggable"
require "suma/http"

module Suma::Mobility::SyncSpin
  include Appydays::Loggable
  # TODO: Configure this
  GBFS_MARKETS = ["portland"].freeze

  def self.sync_all
    (spin = Suma::Vendor[slug: "spin"]) or raise "Spin partner does not exist, cannot run this code"
    services = spin.services_dataset.mobility
    total = 0
    services.each do |vs|
      raise "Cannot sync unknown mobility url: #{vs.inspect}" unless vs.sync_url.include?("/gbfs/v2_2/")
      total += self.sync_gbfs(vs)
    end
    return total
  end

  def self.sync_gbfs(vs)
    resp = Suma::Http.get(vs.sync_url, logger: self.logger)
    rows = []
    resp.parsed_response["data"]["bikes"].each do |bike|
      row = {
        lat: bike["lat"],
        lng: bike["lon"],
        vehicle_id: bike["bike_id"],
        vehicle_type: "escooter",
        vendor_service_id: vs.id,
      }
      rows << row
    end
    Suma::Mobility::Vehicle.db.transaction do
      Suma::Mobility::Vehicle.where(vendor_service: vs).delete
      Suma::Mobility::Vehicle.dataset.multi_insert(rows)
    end
    return rows.length
  end
end
