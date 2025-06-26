# frozen_string_literal: true

require "sentry-ruby"
require "appydays/configurable"
require "appydays/loggable"

require "suma"

module Suma::Sentry
  include Appydays::Configurable
  include Appydays::Loggable

  configurable(:sentry) do
    setting :dsn, ""

    after_configured do
      if self.dsn
        # See https://github.com/getsentry/sentry-ruby/issues/1756
        require "sentry-sidekiq"
        Sentry.init do |config|
          # See https://docs.sentry.io/clients/ruby/config/ for more info.
          config.dsn = dsn
          config.sdk_logger = self.logger
        end
      else
        Sentry.instance_variable_set(:@main_hub, nil)
      end
    end
  end

  def self.enabled?
    return self.dsn.present?
  end

  def self.dsn_host
    return nil unless self.enabled?
    return URI(self.dsn).host
  end
end
