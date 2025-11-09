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
    setting :default_inbox_id, "inb_123"

    after_configured do
      self.client = Frontapp::Client.new(auth_token: self.auth_token, user_agent: Suma::Http.user_agent)
    end
  end
end

class Frontapp::Client
  def create(path, body)
    params = self.post_request_params(body)
    res = @headers.post("#{base_url}#{path}", **params)
    raise Frontapp::Error.from_response(res) unless res.status.success?
    JSON.parse(res.to_s)
  end

  # Front's attachment handling is a mess; if a request includes attachments,
  # it needs to be a multipart form, and nested keys are as document here:
  # https://dev.frontapp.com/docs/attachments-1
  #
  # However, this is simpler said than done, because this makes many assumptions
  # about how clients treated nested keys and forms.
  # For example, a body of `{x: {y: 1}, attachments: [(multipart)]}`
  # is not serialized in the way Front wants via the HTTP gem.
  #
  # (This is a good example of the risk associated with SDK wrappers,
  # even first-party ones, though the one we use is third-party and we should not be using it).
  #
  # Callers who MAY be using multipart requests MUST pass nested params
  # using the keys `{'x[y]' => 1}`, not `{x: {y: 1}}`,
  # because the latter is not serialized correctly into a multipart.
  #
  # To avoid callers having to contain custom logic around which form to use
  # depending on if they have a multipart request (which is very error prone),
  # we try to handle this intelligently:
  #
  # - If the body is a true multipart body, pass it through to the HTTP gem;
  #   assume the caller passes `x[y]` keys if needed, as the caveat above.
  # - If any key is of the form `x[y]` (contains a bracket),
  #   assume the caller wants multipart behavior, and make our own multipart body
  #   (since this is not a multipart request, the HTTP library would use form encoding,
  #   but that doesn't work right so we never want to use it).
  # - The body can be treated as JSON, pass it through, as it serializes JSON right.
  #
  def post_request_params(data)
    hasform = false
    data.each do |k, v|
      # If we have a multipart, let the library handle it always.
      return {form: data} if v.is_a? ::HTTP::FormData::Part
      return {form: data} if v.respond_to?(:to_ary) && v.to_ary.any?(::HTTP::FormData::Part)
      hasform = true if k.is_a?(String) && k.include?("[")
    end
    # No special handling required for json
    return {json: data} unless hasform
    # This is a simple form, but we cannot use form encoding due to Front inconsistencies.
    # So let's use multipart, as explained above.
    return {form: HTTP::FormData::Multipart.new(data)}
  end
end

module Frontapp::Client::Channels
  def create_draft!(channel_id, params={})
    create("channels/#{channel_id}/drafts", params)
  end
end

module Frontapp::Client::Conversations
  def create_conversation(params={})
    create("conversations", params)
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
