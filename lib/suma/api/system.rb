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

  get :useragentz do
    status 200
    browser = Browser.new(request.headers["User-Agent"], accept_language: "en-us")
    {
      device: browser.name,
      platform: browser.platform.name,
      platform_version: browser.platform.version,
      is_android: browser.platform.android?,
      is_ios: browser.platform.ios?,
    }
  end
end
