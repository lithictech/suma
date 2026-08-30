# frozen_string_literal: true

require "browser"
require "grape"

require "suma/api"
require "suma/postgres"

# Health check and other metadata endpoints.
class Suma::API::System < Suma::Service
  format :json

  require "suma/service/helpers"
  helpers Suma::Service::Helpers

  get :healthz do
    Suma::Postgres::Model.db.execute("SELECT 1=1")
    status 200
    {o: "k"}
  end

  get :statusz do
    status 200
    {
      env: Suma::RACK_ENV,
      version: Suma::VERSION,
      release: Suma::RELEASE,
      log_level: Suma.logger.level,
    }
  end

  get :useragent do
    status 200
    use_http_expires_caching 7.days
    browser = Browser.new(request.headers["User-Agent"], accept_language: "en-us")
    ua = {
      device: browser.name,
      platform: browser.platform.name,
      platform_version: browser.platform.version,
      is_android: browser.platform.android?,
      is_ios: browser.platform.ios?,
    }
    present ua, with: UserAgentEntity
  end

  class UserAgentEntity < Grape::Entity
      expose :device, documentation: {type: String}
      expose :platform, documentation: {type: String}
      expose :platform_version, documentation: {type: String}
      expose :is_android
      expose :is_ios
  end
end
