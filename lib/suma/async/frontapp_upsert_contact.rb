# frozen_string_literal: true

require "amigo/job"

class Suma::Async::FrontappUpsertContact
  extend Amigo::Job

  on(/^suma\.member\.(created|updated)$/)

  IGNORED_UPDATE_KEYS = ["updated_at"].freeze

  def _perform(event)
    member = self.lookup_model(Suma::Member, event)
    return unless Suma::Frontapp.configured?
    if event.name == "suma.member.updated"
      important_keys_changed = event.payload[1].keys - IGNORED_UPDATE_KEYS
      return if important_keys_changed.empty?
    end
    member.frontapp.upsert_contact
  end
end
