# frozen_string_literal: true

# Plugin to make an object immutable after creation.
module Sequel::Plugins::Immutable
  __ = 0

  module InstanceMethods
    def before_update
      raise FrozenError, "cannot modify immutable model"
    end
  end
end
