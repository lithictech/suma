# frozen_string_literal: true

require "amigo/scheduled_job"

class Suma::Async::Emailer
  extend Amigo::ScheduledJob

  cron "* * * * *"
  splay 5.seconds

  def _perform
    self.logger.info "sending_pending_emails"
    Suma::Message.send_unsent
  end

  Amigo.register_job(self)
end
