# frozen_string_literal: true

require "frontapp"

require "suma/http"

module Suma::Frontapp
  include Appydays::Configurable
  include Appydays::Loggable

  UNCONFIGURED_AUTH_TOKEN = "get-from-front-add-to-env"

  class << self
    # @return [Frontapp::Client]
    attr_accessor :client

    def configured? = self.auth_token != UNCONFIGURED_AUTH_TOKEN && self.auth_token.present?

    # @param [:email,:phone] source
    # @param [String] value
    def contact_alt_handle(source, value) = "alt:#{source}:#{value}"

    def contact_phone_handle(p) = self.contact_alt_handle("phone", Suma::PhoneNumber.format_e164(p))

    # Convert a numeric ID or string (from a Front URL) into an API ID.
    # See https://community.front.com/developer-q-a-37/how-to-get-api-inbox-id-from-url-inbox-id-2497
    def to_api_id(prefix, id)
      return "#{prefix}_#{id.to_s(36)}" if id.is_a?(Integer)
      return id if id.nil? || id == ""
      return "#{prefix}_#{id.to_i.to_s(36)}" if /^\d+$/.match?(id)
      return id if id.start_with?(prefix)
      raise ArgumentError, "#{id} is not an integer, so must already start with #{prefix}"
    end

    def to_template_id(id) = to_api_id("rsp", id)
    def to_channel_id(id) = to_api_id("cha", id)
    def to_inbox_id(id) = to_api_id("inb", id)

    def make_http_request(method, url, **options)
      options[:headers] ||= {}
      options[:headers]["Authorization"] = "Bearer #{self.auth_token}"
      resp = Suma::Http.execute(
        method,
        "https://api2.frontapp.com#{url}",
        logger: self.logger,
        **options,
      )
      return resp
    end
  end

  configurable(:frontapp) do
    setting :auth_token, UNCONFIGURED_AUTH_TOKEN
    setting :list_sync_enabled, false

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

module Frontapp::Client::MessageTemplates
  def get_message_template(message_template_id)
    get("message_templates/#{message_template_id}")
  end
end

class Frontapp::Client
  include Frontapp::Client::MessageTemplates
end
