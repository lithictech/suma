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
map "/adminapi" do
  run Suma::Apps::AdminAPI.build_app
end
map "/app" do
  run Suma::Apps::Web.to_app
end
map "/admin" do
  run Suma::Apps::Web.to_app
end
run Suma::Apps::Root.to_app
