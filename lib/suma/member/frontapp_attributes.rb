# frozen_string_literal: true

require "suma/frontapp"

class Suma::Member::FrontappAttributes
  def initialize(member)
    @member = member
  end

  def upsert_contact
    if self.contact_id.blank?
      self.create_contact
      return
    end
    self.update_contact
    return
  end

  def create_contact
    contact = Suma::Frontapp.client.create_contact!(self.contact_body.merge(handles: self.contact_handles))
    @member.update(front_contact_id: contact.fetch("id"))
    return contact
  end

  def update_contact
    Suma::Frontapp.client.update_contact!(self.contact_id, self.contact_body)
    return if (handles = self.contact_handles).empty?

    handles.each do |h|
      Suma::Frontapp.client.add_contact_handle!(self.contact_id, h)
    end
  end

  def contact_body
    # In the future, we would look at things like organizations to add custom fields,
    # like the housing partner they are a part of.
    custom_fields = {}
    body = {
      links: [@member.admin_link],
      custom_fields:,
    }
    body[:name] = @member.name if @member.name.present?
    body
  end

  def contact_handles
    h = []
    h << {source: "phone", handle: @member.phone} if @member.phone.present?
    h << {source: "email", handle: @member.email} if @member.email.present?
    h
  end

  def contact_id
    @member.front_contact_id
  end
end
