# frozen_string_literal: true

module Suma::Logutil
  class << self
    def with_tags(tags={}, &)
      Sentry.with_scope do |scope|
        scope&.set_extras(tags)
        SemanticLogger.named_tagged(tags, &)
      end
    end

    # @return [Sentry::Scope]
    def sentry_scope = Sentry.get_current_scope || Sentry::Scope.new
  end
end
