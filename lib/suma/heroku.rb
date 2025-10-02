# frozen_string_literal: true

require "platform-api"

require "suma"

class Suma::Heroku
  include Appydays::Configurable

  configurable(:heroku) do
    # Generate these via heroku authorizations:create -d <friendly name of authorization>
    setting :oauth_id, "", key: "SUMA_HEROKU_OAUTH_ID"
    setting :oauth_token, "", key: "SUMA_HEROKU_OAUTH_TOKEN"
    setting :app_name, "", key: "HEROKU_APP_NAME"

    after_configured do
      @client = nil
    end
  end

  def self.client
    raise "SUMA_HEROKU_OAUTH_TOKEN not set" if self.oauth_token.blank?
    @client ||= PlatformAPI.connect_oauth(self.oauth_token)
    return @client
  end
end
