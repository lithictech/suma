# frozen_string_literal: true

# Feature flags control access to features.
#
# Flags are role and config based:
# - Flags are configured with a comma-separated list of roles (`FEATURE_FLAG_EXPIRED_CARDS=beta,admin`)
# - If the member has a role with that name, they have access.
# - By default, flags have no roles, so are enabled for no one.
# - If `RACK_ENV=test`, flags always pass. Since these flags are designed to avoid any conditional logic
#   in calling code, this avoids special flag-aware test setup code.
module Suma::FeatureFlags
  include Appydays::Configurable

  class Flag
    def initialize(name)
      @name = name
    end

    def check(member, default=nil, &)
      raise Suma::InvalidPrecondition, "member cannot be nil" if member.nil?
      return check_return_type(default, yield) if Suma.test?
      enabled = member.roles.map(&:name).intersect?(Suma::FeatureFlags.send(@name))
      return check_return_type(default, yield) if enabled
      return default
    end

    private def check_return_type(default, got)
      return got if Suma.bool?(default) && Suma.bool?(got) # Special case bools since they don't share a common class.
      raise Suma::InvalidPostcondition, "#{got.class} must be of type #{default.class}" unless got.is_a?(default.class)
      return got
    end
  end

  SPLIT_WORDS = ->(s) { s.split.map(&:strip) }

  configurable :feature_flag do
    setting :test_flag, [], convert: SPLIT_WORDS
    setting :expiring_cards, [], convert: SPLIT_WORDS
  end

  class << self
    def expiring_cards_flag = (@expiring_cards_flag ||= Flag.new(:expiring_cards))
  end
end
