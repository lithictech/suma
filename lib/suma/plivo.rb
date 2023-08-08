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
    # Provisioned numbers in the private account system will be part of this app id.
    setting :anon_proxy_number_app_id, ""
    # In development and testing, we don't want to keep provisioning numbers,
    # since it gets expensive! So provision one number and reuse it here.
    # Note that this short-circuits some HTTP flows, so those still need end-to-end testing.
    setting :shared_override_number, ""
  end

  class << self
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
  end
end
