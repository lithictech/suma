# frozen_string_literal: true

require "active_support"
require "active_support/core_ext"
require "appydays/configurable"
require "appydays/loggable"
require "money"
require "pathname"
require "phony"
require "yajl"

if (heroku_app = ENV.fetch("MERGE_HEROKU_ENV", nil))
  text = `heroku config -j --app=#{heroku_app}`
  json = Yajl::Parser.parse(text)
  json.each do |k, v|
    ENV[k] = v
  end
end

Money.locale_backend = :i18n
Money.rounding_mode = BigDecimal::ROUND_HALF_UP

module Suma
  include Appydays::Loggable
  include Appydays::Configurable

  # Error raised when we cannot take an action
  # because some condition has not been set up right.
  class InvalidPrecondition < RuntimeError; end

  # Error raised when, after we take an action,
  # something we expect to have changed has not changed.
  class InvalidPostcondition < RuntimeError; end

  class ResourceForbidden < RuntimeError; end

  # The owner of objects that should be the same,
  # are different.
  class ResourceOwnerMismatch < ResourceForbidden; end

  # Error when a resource that a member owns is used,
  # but cannot because it is deleted.
  class ResourceDeleted < ResourceForbidden; end

  APPLICATION_NAME = "Suma"
  RACK_ENV = ENV.fetch("RACK_ENV", "development")
  VERSION = ENV.fetch("HEROKU_SLUG_COMMIT", "unknown-version")
  RELEASE = ENV.fetch("HEROKU_RELEASE_VERSION", "unknown-release")
  RELEASE_CREATED_AT = ENV.fetch("HEROKU_RELEASE_CREATED_AT") { Time.at(0).utc.iso8601 }
  WEBDRIVER_TESTS_ENABLED = ENV.fetch("WEBDRIVER_TESTS", false)
  INTEGRATION_TESTS_ENABLED = ENV.fetch("INTEGRATION_TESTS", false)

  DATA_DIR = Pathname(__FILE__).dirname.parent + "data"

  configurable(:suma) do
    setting :log_level_override,
            nil,
            key: "LOG_LEVEL",
            side_effect: ->(v) { Appydays::Loggable.default_level = v if v }
    setting :log_format, nil
    setting :app_url, "http://localhost:22004"
    setting :admin_url, "http://localhost:22014"
    setting :api_url, "http://localhost:#{ENV.fetch('PORT', 22_001)}/api"
    setting :default_currency, "USD", side_effect: ->(v) { Money.default_currency = v }
    setting :bust_idempotency, false
    setting :use_globals_cache, false
    setting :operator_name, "suma"
  end

  require "suma/method_utilities"
  extend Suma::MethodUtilities

  require "suma/sentry"

  def self.load_app
    $stdout.sync = true
    $stderr.sync = true

    Appydays::Loggable.configure_12factor(format: self.log_format, application: APPLICATION_NAME)

    require "suma/postgres"
    Suma::Postgres.load_models
  end

  #
  # :section: Globals cache
  #

  singleton_attr_reader :globals_cache
  @globals_cache = {}

  # If globals caching is enabled, see if there is a cached value under +key+
  # and return it if so. If there is not, evaluate the given block and store that value.
  # Generally used for looking up well-known database objects like certain roles.
  def self.cached_get(key)
    if self.use_globals_cache
      result = self.globals_cache[key]
      return result if result
    end
    result = yield()
    self.globals_cache[key] = result
    return result
  end

  #
  # :section: Errors
  #

  class LockFailed < StandardError; end

  ### Generate a key for the specified Sequel model +instance+ and
  ### any additional +parts+ that can be used for idempotent requests.
  def self.idempotency_key(instance, *parts)
    key = "%s-%s" % [instance.class.implicit_table_name, instance.pk]

    if instance.respond_to?(:updated_at) && instance.updated_at
      parts << instance.updated_at
    elsif instance.respond_to?(:created_at) && instance.created_at
      parts << instance.created_at
    end
    parts << SecureRandom.hex(8) if self.bust_idempotency
    key << "-" << parts.map(&:to_s).join("-") unless parts.empty?

    return key
  end

  #
  # :section: Unambiguous/promo code chars
  #

  # Remove ambiguous characters (L, I, 1 or 0, O) and vowels from possible codes
  # to avoid creating ambiguous codes or real words.
  UNAMBIGUOUS_CHARS = "CDFGHJKMNPQRTVWXYZ23469".chars.freeze

  def self.take_unambiguous_chars(n)
    return Array.new(n) { UNAMBIGUOUS_CHARS.sample }.join
  end

  # Convert a string into something we consistently use for slugs:
  # a-z, 0-9, and underscores only.
  # Milk + Eggs -> milk_eggs
  def self.to_slug(s)
    return s.downcase.gsub(/[^a-z0-9]/, "_").squeeze("_")
  end

  # Return the request user and admin stored in TLS. See service.rb for implementation.
  #
  # Note that the second return value (the admin) will be nil if not authed as an admin,
  # and if an admin is impersonating, the impersonated member is the first value.
  #
  # Both values will be nil if no user is authed or this is called outside of a request.
  #
  # Usually these fields should only be used where it would be sufficiently difficult
  # to pass the current user through the stack.
  # In the API, you should instead use the 'current member' methods
  # like current_member, and admin_member, NOT using TLS.
  # Outside of the API, this should only be used for things like auditing;
  # it should NOT, for example, ever be used to determine the 'member owner' of objects
  # being created. Nearly all code will be simpler if the current member
  # is passed around. But it would be too complex for some code (like auditing)
  # so this system exists. Overuse of request_user_and_admin will inevitably lead to regret.
  def self.request_user_and_admin
    return Thread.current[:suma_request_user], Thread.current[:suma_request_admin]
  end

  # Return the request user stored in TLS. See service.rb for details.
  def self.set_request_user_and_admin(user, admin, &block)
    if !user.nil? && !admin.nil? && self.request_user_and_admin != [nil, nil]
      raise Suma::InvalidPrecondition, "request user is already set: #{user}, #{admin}"
    end
    Thread.current[:suma_request_user] = user
    Thread.current[:suma_request_admin] = admin
    return if block.nil?
    begin
      yield
    ensure
      Thread.current[:suma_request_user] = nil
      Thread.current[:suma_request_admin] = nil
    end
  end
end

require "suma/aggregate_result"
require "suma/phone_number"
require "suma/typed_struct"
