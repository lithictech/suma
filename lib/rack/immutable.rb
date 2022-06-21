# frozen_string_literal: true

require "rack"

class Rack::Immutable
  # By default, match strings like 'main.abc123.js'.
  # Assume the fingerprint is a Git SHA value of at least 6 characters,
  # comes before the extension, and has some preceding segment of the path.
  DEFAULT_MATCH = /.*\.[A-Za-z\d]{6}[A-Za-z\d]*\.[a-z]+/
  IMMUTABLE = "public, max-age=604800, immutable"

  def initialize(app, match: nil, cache_control: nil)
    @app = app
    @match = match || DEFAULT_MATCH
    @cache_control = cache_control || IMMUTABLE
  end

  def call(env)
    status, headers, body = @app.call(env)
    headers[Rack::CACHE_CONTROL] = @cache_control if
      self._matches(env["PATH_INFO"], env)
    return status, headers, body
  end

  def _matches(path, env)
    return @match == path if @match.is_a?(String)
    return @match.match?(path) if @match.is_a?(Regexp)
    return @match.call(env)
  end
end
