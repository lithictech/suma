# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "suma"
Suma.load_app

require "suma/apps"
require "suma/async"

Suma::Async.setup_web

map "/api" do
  run Suma::Apps::API.build_app
end
map Suma::Apps::MOUNT_PATHS.fetch(Suma::Apps::AdminAPI) do
  run Suma::Apps::AdminAPI.build_app
end
map Suma::Apps::WEB_MOUNT_PATH do
  run Suma::Apps::Web.to_app
end
map "/admin" do
  run Suma::Apps::Admin.to_app
end
map "/sidekiq" do
  run Suma::Apps::SidekiqWeb.to_app
end
if Suma::Service.swagger_enabled
  map "/swagger" do
    run Suma::Apps::Swagger
  end
end
run Suma::Apps::Root.to_app
