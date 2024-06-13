# frozen_string_literal: true

require "suma/oye"

class Suma::Member::OyeAttributes
  def initialize(member)
    @member = member
    @marketing_key = Suma::Oye.sms_marketing_preferences_key
  end

  OPTIN_STATUS = "active"
  OPTOUT_STATUS = "inactive"
  STATUS = {
    true => OPTIN_STATUS,
    false => OPTOUT_STATUS,
  }.freeze

  # If contact is missing, add it. Always update oye contact status sms
  # with current member marketing subscription preferences.
  def upsert_sms_status
    self._add_contact_id if self.contact_id.blank?
    self._update_contact_status
  end

  def _add_contact_id
    contacts = Suma::Oye.get_contacts
    return unless (contact = contacts.find { |c| Suma::PhoneNumber::US.normalize(c.fetch("number")) === @member.phone })
    @member.update(oye_contact_id: contact.fetch("id").to_s)
  end

  def _update_contact_status
    marketing_subscr = @member.preferences!.subscription(@marketing_key)
    oye_sms_status = STATUS.fetch(marketing_subscr[:opted_in])
    Suma::Oye.bulk_update_contacts(contacts: [{id: self.contact_id, status: oye_sms_status}])
  end

  def contact_id
    @member.oye_contact_id
  end
end
