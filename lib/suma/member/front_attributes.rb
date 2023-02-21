# frozen_string_literal: true

require "suma/front"

class Suma::Member::FrontAttributes
  def initialize(member)
    @member = member
  end

  def upsert_contact
    # In the future, we would look at things like organizations to add custom fields,
    # like the housing partner they are a part of.
    custom_fields = {}
    body = {
      links: [@member.admin_link],
      custom_fields:,
    }
    body[:name] = @member.name if @member.name.present?

    handles = []
    handles << {source: "phone", handle: @member.phone} if @member.phone.present?
    handles << {source: "email", handle: @member.email} if @member.email.present?
    if (contact_id = @member.front_contact_id).blank?
      contact = Suma::Front.client.create_contact!(body.merge(handles:))
      @member.update(front_contact_id: contact.fetch("id"))
    else
      Suma::Front.client.update_contact!(contact_id, body)
      handles.each do |h|
        puts h
        Suma::Front.client.add_contact_handle!(contact_id, h)
      end
    end
  end
end
