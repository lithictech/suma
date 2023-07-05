# frozen_string_literal: true

require "suma/anon_proxy"

class Suma::AnonProxy::LogicAdapter
  REGISTRY = {}.freeze

  def self.register(key, cls)
    REGISTRY[key] = cls
  end

  # @return [Suma::AnonProxy::LogicAdapter]
  def self.lookup!(key)
    return REGISTRY.fetch(key).new
  end
end

require "suma/anon_proxy/logic_adapter/fake"
require "suma/anon_proxy/logic_adapter/lime"
require "suma/anon_proxy/logic_adapter/lyft"

Suma::AnonProxy::LogicAdapter.register("fake", Suma::AnonProxy::LogicAdapter::Fake)
Suma::AnonProxy::LogicAdapter.register("lime", Suma::AnonProxy::LogicAdapter::Lime)
Suma::AnonProxy::LogicAdapter.register("lyft", Suma::AnonProxy::LogicAdapter::Lyft)
