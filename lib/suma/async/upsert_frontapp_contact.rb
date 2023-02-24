# frozen_string_literal: true

require "amigo/job"

class Suma::Async::UpsertFrontappContact
  extend Amigo::Job

  on "suma.member.*"

  def _perform(event)
    member = self.lookup_model(Suma::Member, event)
    return unless Suma::Frontapp.configured?
    if event.name == "suma.member.updated"
      import_key_changers = event.payload[1].keys - ["updated_at", "frontapp_contact_id"]
      return if import_key_changers.empty?
    end
    member.frontapp.upsert_contact
  end

  Amigo.register_job(self)
end
