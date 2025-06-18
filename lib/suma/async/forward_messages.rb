# frozen_string_literal: true

require "amigo/scheduled_job"
require "suma/async"
require "suma/message/forwarder"

class Suma::Async::ForwardMessages
  extend Amigo::ScheduledJob

  sidekiq_options(Suma::Async.cron_job_options)
  cron "*/5 * * * *"
  splay 15

  def _perform
    return unless Suma::Message::Forwarder.configured?
    Suma::Message::Forwarder.new(now: Time.now).run
  end
end
