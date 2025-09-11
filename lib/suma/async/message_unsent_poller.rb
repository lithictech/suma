# frozen_string_literal: true

require "amigo/scheduled_job"

class Suma::Async::MessageUnsentPoller
  extend Amigo::ScheduledJob
  include Suma::Async::JobUtils

  sidekiq_options(Suma::Async.cron_job_options)
  cron "*/5 * * * *"
  splay 5.seconds

  def _perform
    sent = Suma::Message.send_unsent
    self.set_job_tags(sent_messages: sent.count)
  end
end
