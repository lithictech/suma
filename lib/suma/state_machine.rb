# frozen_string_literal: true

require "suma"

class Suma::StateMachine
  class Error < RuntimeError; end

  class FailedTransition < Error
    attr_reader :wrapped

    def initialize(msg, wrapped=nil)
      if wrapped
        super("#{msg}: #{wrapped}")
      else
        super(msg)
      end
      @wrapped = wrapped
    end
  end

  class Helpers
    def initialize(obj, name)
      @obj = obj
      @name = name
      @machine = @obj.class.state_machines[@name]
    end

    # @return [Array<Symbol>]
    def available_events(sm) = @machines.events.valid_for(sm).map(&:name)
  end
end
