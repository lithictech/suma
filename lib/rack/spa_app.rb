# frozen_string_literal: true

require "rack/immutable"
require "rack/lambda_app"
require "rack/simple_redirect"
require "rack/spa_rewrite"

class Rack::SpaApp
  def self.dependencies(build_folder, immutable: true, enforce_ssl: true, service_worker_allowed: nil)
    result = []
    result << [Rack::SslEnforcer, {redirect_html: false}] if enforce_ssl
    result << [Rack::ConditionalGet, {}]
    result << [Rack::ETag, {}]
    result << [Rack::Immutable, {match: immutable.is_a?(TrueClass) ? nil : immutable}] if immutable
    result << [Rack::SpaRewrite, {index_path: "#{build_folder}/index.html", html_only: true}]
    result << [Rack::ServiceWorkerAllowed, {scope: service_worker_allowed}] if service_worker_allowed
    result << [Rack::Static, {urls: [""], root: build_folder.to_s, cascade: true}]
    result << [Rack::SpaRewrite, {index_path: "#{build_folder}/index.html", html_only: false}]
    return result
  end

  def self.install(builder, dependencies)
    dependencies.each { |cls, opts| builder.use(cls, **opts) }
  end

  def self.run(builder)
    builder.run Rack::LambdaApp.new(->(_) { raise "Should not see SpaApp fallback" })
  end

  def self.run_spa_app(builder, build_folder, enforce_ssl: true, immutable: true, **kw)
    deps = self.dependencies(build_folder, enforce_ssl:, immutable:, **kw)
    self.install(builder, deps)
    self.run(builder)
  end
end
