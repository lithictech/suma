# frozen_string_literal: true

require "concurrent"

module Suma
  SHUTTING_DOWN = Concurrent::AtomicBoolean.new(false)
  SHUTTING_DOWN_EVENT = Concurrent::Event.new

  module Signals
    class << self
      def reset
        Suma::SHUTTING_DOWN.make_false
        Suma::SHUTTING_DOWN_EVENT.reset
      end

      def install
        ["TERM"].each do |sig|
          original = Signal.trap(sig) do
            self.send("handle_#{sig.downcase}")
            original.call if original.respond_to?(:call)
          end
        end
      end

      def handle_term
        Suma::SHUTTING_DOWN.make_true
        Suma::SHUTTING_DOWN_EVENT.set
      end
    end
  end
end
