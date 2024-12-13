# frozen_string_literal: true

require "frontapp"

require "suma/http"
require "suma/method_utilities"

module Suma::Frontapp
  include Appydays::Configurable
  extend Suma::MethodUtilities

  UNCONFIGURED_AUTH_TOKEN = "get-from-front-add-to-env"

  class << self
    # @return [Frontapp::Client]
    attr_accessor :client

    def configured? = self.auth_token != UNCONFIGURED_AUTH_TOKEN && self.auth_token.present?
  end

  configurable(:frontapp) do
    setting :auth_token, UNCONFIGURED_AUTH_TOKEN
    setting :marketing_sms_list_id, ""
    setting :marketing_email_list_id, ""

    after_configured do
      self.client = Frontapp::Client.new(auth_token: self.auth_token, user_agent: Suma::Http.user_agent)
    end
  end
end

module ::Frontapp
  class Client
    module ContactGroups
      # This method is currently missing from the Front gem
      def remove_contacts_from_contact_group!(group_id, params={})
        cleaned = params.permit(:contact_ids)
        delete("contact_groups/#{group_id}/contacts", cleaned)
      end
    end
  end
end
