# frozen_string_literal: true

require "suma/frontapp"

class Suma::Member::FrontappAttributes
  def initialize(member)
    @member = member
  end

  def upsert_contact
    if @member.frontapp_contact_id.blank?
      self._create_contact
    else
      self._update_contact
    end
    return
  end

  def _create_contact
    contact = Suma::Frontapp.client.create_contact!(self._contact_body.merge(handles: self._contact_handles))
    @member.update(frontapp_contact_id: contact.fetch("id"))
    return contact
  rescue Frontapp::ConflictError => e
    @member.update(frontapp_contact_id: e.message)
    self._update_contact
  end

  def _update_contact
    Suma::Frontapp.client.update_contact!(self.contact_id, self._contact_body)
    return if (handles = self._contact_handles).empty?

    handles.each do |h|
      Suma::Frontapp.client.add_contact_handle!(self.contact_id, h)
    end
  rescue Frontapp::NotFoundError
    @member.update(frontapp_contact_id: "")
    self._create_contact
  end

  def _contact_body
    body = {
      links: [@member.admin_link],
      # NOTE: Setting things like customFields or groupNames will REPLACE existing ones,
      # so be very careful if we end up using them.
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

  def contact_id
    return "alt:phone:#{Suma::PhoneNumber.format_e164(@member.phone)}"
  end
end
