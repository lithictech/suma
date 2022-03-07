# frozen_string_literal: true

lib = File.expand_path("lib", "#{__dir__}/..")
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "appydays/dotenviable"
Appydays::Dotenviable.load

require "suma"
Suma.load_app

require "suma/async"
Suma::Async.require_jobs
Amigo.start_scheduler
Sentry.configure_scope do |scope|
  scope.set_tags(application: "worker")
end
