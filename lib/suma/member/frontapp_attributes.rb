# frozen_string_literal: true

require "suma/frontapp"

class Suma::Member::FrontappAttributes
  def initialize(member)
    @member = member
  end

  # Upsert the Front contact making sure we use existing contacts with the same phone/email,
  # merging them as needed.
  def upsert_contact
    # If this fails for a conflict, the email and/or phone are in use already.
    Suma::Frontapp.client.create_contact!(self._contact_body.merge(handles: self._contact_handles))
  rescue Frontapp::ConflictError
    self._update_contact
  end

  def _update_contact
    email_contact = self._get_contact_by_alt_id(:email, @member.email)
    phone_contact = self._get_contact_by_alt_id(:phone, @member.phone)

    raise Suma::InvalidPostcondition, "should not have reached this code if phone and email are not in use" if
      email_contact.nil? && phone_contact.nil?

    updateable_contact = phone_contact || email_contact
    if email_contact && phone_contact && email_contact.fetch("id") != phone_contact.fetch("id")
      # We have both contacts, so need to merge them into one.
      updateable_contact = Suma::Frontapp.client.create(
        "contacts/merge",
        {contact_ids: [phone_contact.fetch("id"), email_contact.fetch("id")]},
      )
    end

    Suma::Frontapp.client.update_contact!(updateable_contact.fetch("id"), self._contact_body)
    self._contact_handles.each do |h|
      Suma::Frontapp.client.add_contact_handle!(updateable_contact.fetch("id"), h)
    end
  end

  def _contact_body
    body = {
      links: [@member.admin_link],
      # NOTE: Setting things like customFields or listNames will REPLACE existing ones,
      # so be very careful if we end up using them.
      custom_fields: {
        "SMS Marketing Opted Out" => @member.preferences!.marketing_sms_optout,
        "Language" => @member.preferences!.preferred_language_name,
        "Address" => @member.legal_entity.address&.one_line_address || "",
      },
    }
    body[:name] = @member.name if @member.name.present?
    body
  end

  def _contact_handles
    h = []
    h << {source: "phone", handle: @member.phone} if @member.phone.present?
    h << {source: "email", handle: @member.email} if @member.email.present?
    h
  end

  def _get_contact_by_alt_id(source, value)
    return nil if value.blank?
    h = Suma::Frontapp.contact_alt_handle(source, value)
    begin
      return Suma::Frontapp.client.get_contact(h)
    rescue Frontapp::NotFoundError
      return nil
    end
  end
end
