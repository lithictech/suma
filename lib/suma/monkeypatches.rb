# frozen_string_literal: true

Money.locale_backend = :i18n
Money.rounding_mode = BigDecimal::ROUND_HALF_UP

# rubocop:disable Style/OneClassPerFile
class Money
  class << self
    def cache = @cache ||= {}

    # Since Money instances are immutable, we can cache certain instances (0 cents)
    # to reduce allocations.
    def new(obj, currency=Money.default_currency, options={})
      # rubocop:disable Style/NumericPredicate
      if obj == 0
        # rubocop:enable Style/NumericPredicate
        zero = self.cache[currency] ||= super
        return zero
      end
      return super
    end
  end
end

module SemanticLogger
  class << self
    alias original_get []
    def [](key)
      logger = self.original_get(key)
      return logger unless Suma.respond_to?(:log_level_overrides)
      if (level = Suma.log_level_overrides[logger.name])
        logger.level = level
      end
      return logger
    end
  end
end

# rubocop:enable Style/OneClassPerFile
