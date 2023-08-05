# frozen_string_literal: true

require "appydays/configurable"
require "appydays/loggable"
require "suma/method_utilities"

module Suma::Plivo
  extend Suma::MethodUtilities
  include Appydays::Configurable
  include Appydays::Loggable

  configurable(:plivo) do
    setting :auth_id, "MA_FAKE_A4NTUWNMEYZW"
    setting :auth_token, "fake-auth-token"
    # Usually a WebhookDB url
    setting :sms_status_url, "https://example.com"
    setting :anon_proxy_number_app_id, ""
  end

  class << self
    attr_reader :client

    # Do not use the Plivo SDK, it uses very old dependencies and is overall very hard to use
    # with a combination of symbols, strings, and accessors inconsistently.
    def request(method, tail, body: nil, **options)
      tail = tail.delete_suffix("/")
      url = "https://api.plivo.com/v1/Account/#{self.auth_id}#{tail}/"
      options[:basic_auth] = {username: self.auth_id, password: self.auth_token}
      options[:logger] = self.logger
      if body
        options[:headers] = {"Content-Type" => "application/json"}
        options[:body] = body.to_json
      end
      return Suma::Http.execute(method, url, **options)
    end

    def send_sms(from, to, body)
      body = {
        src: from,
        dst: to,
        text: body,
        url: self.sms_status_url,
      }
      return self.request(:post, "/Message", body:)
    end
  end
end
