# frozen_string_literal: true

require "rack/immutable"
require "rack/lambda_app"
require "rack/simple_redirect"
require "rack/spa_rewrite"

class Rack::SpaApp
  def self.dependencies(build_folder, immutable: true, enforce_ssl: true)
    result = []
    result << [Rack::SslEnforcer, {redirect_html: false}] if enforce_ssl
    result.concat(
      [
        [Rack::ConditionalGet, {}],
        [Rack::ETag, {}],
      ],
    )
    result << [Rack::Immutable, {match: immutable.is_a?(TrueClass) ? nil : immutable}] if immutable
    result.concat(
      [
        [Rack::SpaRewrite, {index_path: "#{build_folder}/index.html", html_only: true}],
        [Rack::Static, {urls: [""], root: build_folder.to_s, cascade: true}],
        [Rack::SpaRewrite, {index_path: "#{build_folder}/index.html", html_only: false}],
      ],
    )
    return result
  end

  def self.install(builder, dependencies)
    dependencies.each { |cls, opts| builder.use(cls, **opts) }
  end

  def self.run(builder)
    builder.run Rack::LambdaApp.new(->(_) { raise "Should not see SpaApp fallback" })
  end

  def self.run_spa_app(builder, build_folder, enforce_ssl: true, immutable: true)
    deps = self.dependencies(build_folder, enforce_ssl:, immutable:)
    self.install(builder, deps)
    self.run(builder)
  end
end
