# frozen_string_literal: true

require "amigo/job"

class Suma::Async::OyeSyncFromMessagePrefs
  extend Amigo::Job

  on "suma.message.preferences.updated"

  def _perform(event)
    prefs = self.lookup_model(Suma::Message::Preferences, event)
    case event.payload[1]
      when changed(:marketing_optout), changed(:preferred_language)
        Suma::Oye.update_oye_from_members([prefs.member])
    end
  end
end
