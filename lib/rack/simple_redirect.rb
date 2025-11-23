# frozen_string_literal: true

require "rack"

# Redirect a request based on the route it matches.
class Rack::SimpleRedirect
  # The keys in +routes+ can be strings, regular expressions, or callables.
  # For a key that matches (using == for strings, .match?(path) for regexes,
  # or call(env) for callables), the Location in the redirect
  # is equal to the value of the key, or if the value is a callable,
  # the returned result of calling the value with env.
  def initialize(app, routes: {}, status: 302)
    @app = app
    @routes = routes
    @status = status
  end

  def call(env)
    path = env["PATH_INFO"]
    loc = nil
    @routes.each do |route, result|
      if self._matches(path, env, route)
        loc = result.respond_to?(:call) ? result[env] : result
        break
      end
    end
    return @app.call(env) if loc.nil?
    loc = "#{loc}?#{env['QUERY_STRING']}" if env["QUERY_STRING"].present?
    return [@status, {"Location" => loc}, []]
  end

  def _matches(path, env, route)
    return route == path if route.is_a?(String)
    return route.match?(path) if route.is_a?(Regexp)
    return route.call(env)
  end
end
