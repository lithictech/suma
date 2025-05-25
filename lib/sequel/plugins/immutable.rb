# frozen_string_literal: true

# Plugin to make an object immutable after creation.
module Sequel::Plugins::Immutable
end

module Sequel::Plugins::Immutable::InstanceMethods
  def before_update
    raise FrozenError, "cannot modify immutable model"
  end
end
