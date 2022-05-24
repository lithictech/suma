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
    path = env["REQUEST_PATH"]
    loc = nil
    @routes.each do |route, result|
      if self._matches(path, env, route)
        loc = result.respond_to?(:call) ? result[env] : result
        break
      end
    end
    return @app.call(env) if loc.nil?
    return [@status, {"Location" => loc}, []]
  end

  def _matches(path, env, route)
    return route == path if route.is_a?(String)
    return route.match?(path) if route.is_a?(Regexp)
    return route.call(env)
  end

  def _check_routes_opts(h)
    h.each do |k, v|
      case k
        when String, Regexp, Proc
          nil
        else
          raise "SimpleRedirect routes keys must be strings, regexes, or procs"
      end
      case v
        when String, Proc
          nil
        else
          raise "SimpleRedirect routes values must be strings or procs"
      end
    end
  end
end
