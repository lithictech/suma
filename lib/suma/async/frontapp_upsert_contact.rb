# frozen_string_literal: true

require "amigo/job"

class Suma::Async::FrontappUpsertContact
  extend Amigo::Job

  on(/^suma\.member\.(created|updated)$/)

  def _perform(event)
    member = self.lookup_model(Suma::Member, event)
    return unless Suma::Frontapp.configured?
    if event.name == "suma.member.updated"
      import_key_changers = event.payload[1].keys - ["updated_at"]
      return if import_key_changers.empty?
    end
    member.frontapp.upsert_contact
  end
end
