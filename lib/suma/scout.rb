# frozen_string_literal: true

require "appydays/configurable"

module Suma::Scout
  include Appydays::Configurable

  configurable(:scout) do
    setting :key, ""
    setting :monitor, false
  end

  DEFAULT_CONFIG = {
    # Fix the Sentry conflict on Net::HTTP instrumentation.
    "SCOUT_USE_PREPEND" => "true",
    # Disable automatic controller naming.
    "SCOUT_DISABLED_INSTRUMENTS" => "Grape",
  }.freeze

  class << self
    # Check monitor is true and a key is present.
    def monitoring? = self.monitor && self.key.present?

    # Require scout_apm and install the agent, if configured.
    # Requiring the code has side effects and warnings,
    # so we only do it if needed.
    def install?
      return false unless Suma::Scout.monitoring?
      # ENV setup must be done BEFORE importing scout_apm.
      DEFAULT_CONFIG.each do |k, v|
        ENV[k] = v unless ENV.key?(k)
      end
      require "scout_apm"
      ScoutApm::Rack.install!
      return true
    end
  end

  class RackMiddleware
    def initialize(app)
      @app = app
    end

    def call(env)
      return @app.call(env) unless Suma::Scout.monitoring?

      reqmethod = env["REQUEST_METHOD"]
      ScoutApm::Rack.transaction("#{reqmethod} #{env['PATH_INFO'].delete_suffix('/')}", env) do
        result = @app.call(env)
        # By now Grape has populated env, so update the name
        if (route = env["grape.routing_args"]&.dig(:route_info)&.pattern&.origin)
          ScoutApm::Transaction.rename("#{reqmethod} #{route.delete_suffix('/')}")
        end
        result
      end
    end
  end
end
