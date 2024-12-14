# frozen_string_literal: true

require "suma/http"

module Suma::Oye
  include Appydays::Configurable
  include Appydays::Loggable

  OPTIN_FOR_STATUS = {
    "active" => true,
    "inactive" => false,
  }.freeze
  STATUS_FOR_OPTIN = OPTIN_FOR_STATUS.invert.freeze

  UNCONFIGURED_ORGANIZATION_AUTH_TOKEN = "get-from-oyetext-add-to-env"

  configurable(:oye) do
    setting :api_root, "https://app.oyetext.org/api/v1"
    setting :auth_token, UNCONFIGURED_ORGANIZATION_AUTH_TOKEN
  end

  class << self
    def configured? = self.auth_token != UNCONFIGURED_ORGANIZATION_AUTH_TOKEN

    def api_headers
      return {
        "Authorization" => "Bearer #{self.auth_token}",
      }
    end

    def bulk_update_contacts(contacts:)
      response = Suma::Http.post(
        self.api_root + "/contacts/bulk_update",
        {contacts:},
        method: :put,
        headers: self.api_headers,
        logger: self.logger,
      )
      return response.parsed_response
    end

    # Given all contacts in Oye which have members in Suma,
    # update their Suma marketing opt in/out status based on what's in Oye.
    def update_members_from_oye

    end

    # Given a list of members, send their Suma opt in/out status to Oye.
    # Should be done whenever a member changes their opt in/out status.
    def update_oye_from_members(members)

    end
  end
end
