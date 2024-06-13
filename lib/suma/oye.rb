# frozen_string_literal: true

require "suma/http"

module Suma::Oye
  include Appydays::Configurable
  include Appydays::Loggable

  SMS_STATUS_OPT_OUT = "inactive"
  SMS_STATUS_OPT_IN = "active"

  STATUS = {
    SMS_STATUS_OPT_OUT => false,
    SMS_STATUS_OPT_IN => true,
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

  def self.get_contacts
    response = Suma::Http.get(
      self.api_root + "/contacts", headers: self.api_headers, logger: self.logger,
    )
    return response.parsed_response
  end

  def self.bulk_update_contacts(contacts:)
    response = Suma::Http.put(
      self.api_root + "/contacts/bulk_update",
      {contacts:},
      headers: self.api_headers,
      logger: self.logger,
    )
    return response.parsed_response
  end
end
