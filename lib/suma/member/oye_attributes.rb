# frozen_string_literal: true

require "suma/oye"

class Suma::Member::OyeAttributes
  def initialize(member)
    @member = member
    @marketing_key = Suma::Oye.sms_marketing_preferences_key
  end

  # If contact ID is missing, attempt to find and add it to member.
  # Only sync/update contact status when contact ID is set.
  def update_contact_sms_status
    return unless Suma::Oye.configured?
    if self.contact_id.blank?
      contacts = Suma::Oye.get_contacts(Suma::PhoneNumber.format_e164(@member.phone))
      return if contacts.empty?
      @member.update(oye_contact_id: contacts.first.fetch("id").to_s)
    end
    oye_sms_status = Suma::Oye::STATUS_MATCH.invert.fetch(self.marketing_subscription[:opted_in])
    Suma::Oye.bulk_update_contacts(contacts: [{id: self.contact_id, status: oye_sms_status}])
  end

  def marketing_subscription
    @member.preferences!.subscription(@marketing_key)
  end

  def contact_id
    @member.oye_contact_id
  end
end
