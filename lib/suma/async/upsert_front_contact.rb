# frozen_string_literal: true

require "amigo/job"

class Suma::Async::UpsertFrontContact
  extend Amigo::Job

  on "suma.member.*"

  def _perform(event)
    self.lookup_model(Suma::Member, event)
  end

  Amigo.register_job(self)
end
