# frozen_string_literal: true

require "suma/http"

module Suma::Oye
  include Appydays::Configurable
  include Appydays::Loggable

  OPTIN_STATUS = "active"
  OPTOUT_STATUS = "inactive"

  STATUS_MATCH = {
    OPTIN_STATUS => true,
    OPTOUT_STATUS => false,
  }.freeze

  UNCONFIGURED_ORGANIZATION_AUTH_TOKEN = "get-from-oyetext-add-to-env"

  configurable(:oye) do
    setting :api_root, "https://app.oyetext.org/api/v1"
    setting :auth_token, UNCONFIGURED_ORGANIZATION_AUTH_TOKEN
    setting :sms_marketing_preferences_key, :marketing
  end

  def self.configured? = self.auth_token != UNCONFIGURED_ORGANIZATION_AUTH_TOKEN

  def self.api_headers
    return {
      "Authorization" => "Bearer #{self.auth_token}",
    }
  end

  # Query contacts by phone number, first name or last name
  def self.get_contacts(search=nil)
    query = {}
    query = query.merge(search:) unless search.nil?
    response = Suma::Http.get(
      self.api_root + "/contacts", query, headers: self.api_headers, logger: self.logger,
    )
    return response.parsed_response
  end

  def self.bulk_update_contacts(contacts:)
    response = Suma::Http.post(
      self.api_root + "/contacts/bulk_update",
      {contacts:},
      method: :put,
      headers: self.api_headers,
      logger: self.logger,
    )
    return response.parsed_response
  end

  # Syncs oye contact sms preferences with suma member preferences.
  # If member can't be found by contact id, check phone number and
  # update their contact id if member is found.
  # Update member marketing sms preferences when available.
  def self.sync_contact_sms_preferences
    contacts = self.get_contacts
    contacts.each do |c|
      member = Suma::Member[oye_contact_id: c.fetch("id")]
      if member.nil?
        phone = Suma::PhoneNumber::US.normalize(c.fetch("number"))
        next unless Suma::PhoneNumber::US.valid_normalized?(phone)
        next unless (member = Suma::Member[phone:])
        member.update(oye_contact_id: c.fetch("id").to_s)
      end
      next if member.nil?
      member_subscr = member.oye.marketing_subscription
      member_opted_in = STATUS_MATCH.fetch(c.fetch("status"))
      next if member_opted_in === member_subscr[:opted_in]
      member_subscr.set_from_opted_in(member_opted_in)
      member.preferences.save_changes
    end
  end
end
