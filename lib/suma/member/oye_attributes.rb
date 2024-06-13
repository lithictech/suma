# frozen_string_literal: true

require "suma/oye"

class Suma::Member::OyeAttributes
  def initialize(member)
    @member = member
    @marketing_key = Suma::Oye.sms_marketing_preferences_key
  end

  # If contact ID is missing, add it to member. Always update oye contact
  # sms preferences so that member sms preferences stay in sync.
  def upsert_sms_status
    return unless Suma::Oye.configured?
    self._add_contact_id if self.contact_id.blank?
    self._update_contact_status
  end

  def _add_contact_id
    contacts = Suma::Oye.get_contacts
    return unless (contact = contacts.find { |c| Suma::PhoneNumber::US.normalize(c.fetch("number")) === @member.phone })
    @member.update(oye_contact_id: contact.fetch("id").to_s)
  end

  def _update_contact_status
    marketing_subscr = self.marketing_subscription
    oye_sms_status = Suma::Oye::TO_OYE_STATUS.fetch(marketing_subscr[:opted_in])
    Suma::Oye.bulk_update_contacts(contacts: [{id: self.contact_id, status: oye_sms_status}])
  end

  def marketing_subscription
    @member.preferences!.subscription(@marketing_key)
  end

  def contact_id
    @member.oye_contact_id
  end
end
