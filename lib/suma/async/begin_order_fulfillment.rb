# frozen_string_literal: true

require "amigo/scheduled_job"

class Suma::Async::BeginOrderFulfillment
  extend Amigo::ScheduledJob

  sidekiq_options(Suma::Async.cron_job_options)
  cron "*/5 * * * *"

  def _perform
    return unless (orders = Suma::Commerce::Order.ready_for_fulfillment)
    orders.each do |o|
      o.begin_fulfillment
      o.save_changes
    end
  end
end
