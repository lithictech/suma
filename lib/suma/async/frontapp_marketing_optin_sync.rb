# frozen_string_literal: true

require "amigo/job"

class Suma::Async::FrontappMarketingOptinSync
  extend Amigo::Job

  on "suma.message.preferences.updated"

  def _perform(event)
    prefs = self.lookup_model(Suma::Message::Preferences, event)
    return unless Suma::Frontapp.configured?
    self._sync_lists(prefs, event.payload[1])
  end

  def _sync_lists(prefs, changes)
    case changes
      when changed(:marketing_sms_optout, to: true)
        sync_method = :remove_contacts_from_contact_group!
        list_field = :marketing_sms_list_id
        change_attr = :marketing_sms_optout
      when changed(:marketing_sms_optout, to: false)
        sync_method = :add_contacts_to_contact_group!
        list_field = :marketing_sms_list_id
        change_attr = :marketing_sms_optout
      when changed(:marketing_email_optout, to: true)
        sync_method = :remove_contacts_from_contact_group!
        list_field = :marketing_email_list_id
        change_attr = :marketing_email_optout
      when changed(:marketing_email_optout, to: false)
        sync_method = :add_contacts_to_contact_group!
        list_field = :marketing_email_list_id
        change_attr = :marketing_email_optout
      else
        return
    end
    list_id = Suma::Frontapp.send(list_field)
    return if list_id.blank?
    Suma::Frontapp.client.send(sync_method, list_id, {contact_ids: [prefs.member.frontapp_contact_id]})
    changes.delete(change_attr.to_s)
    _sync_lists(prefs, changes)
  end
end
