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

    # @param [:email,:phone] source
    # @param [String] value
    def contact_alt_handle(source, value) = "alt:#{source}:#{value}"

    def contact_phone_handle(p) = self.contact_alt_handle("phone", Suma::PhoneNumber.format_e164(p))
  end

  configurable(:frontapp) do
    setting :auth_token, UNCONFIGURED_AUTH_TOKEN

    after_configured do
      self.client = Frontapp::Client.new(auth_token: self.auth_token, user_agent: Suma::Http.user_agent)
    end
  end
end

module Frontapp::Client::Channels
  def create_draft!(channel_id, params={})
    create("channels/#{channel_id}/drafts", params)
  end
end
