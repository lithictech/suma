# frozen_string_literal: true

require "amigo/scheduled_job"

class Suma::Async::LyftPassTripSync
  extend Amigo::ScheduledJob

  sidekiq_options(Suma::Async.cron_job_options)
  cron "*/20 * * * *"
  splay 5.seconds

  def _perform
    return if Suma::Lyft.pass_email.blank?
    lp = Suma::Lyft::Pass.from_config
    lp.authenticate
    Suma::Lyft::Pass.programs_dataset.each do |program|
      lp.sync_trips_from_program(program)
    end
  end
end
