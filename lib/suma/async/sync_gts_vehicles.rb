# frozen_string_literal: true

require "amigo/scheduled_job"
require "suma/mobility/good_travel_solutions"

class Suma::Async::SyncGtsVehicles
  extend Amigo::ScheduledJob

  sidekiq_options(Suma::Async.cron_job_options)
  cron Suma::Mobility::GoodTravelSolutions.sync_cron
  splay 0

  def _perform
    Suma::Mobility::GoodTravelSolutions.access_details.each do |ad|
      Suma::Mobility::Gbfs::VendorSync.new(
        client: ad.gbfs_client,
        vendor: ad.mobility_vendor,
        component: Suma::Mobility::Gbfs::FreeBikeStatus.new,
      ).sync_all
    end
  end
end
