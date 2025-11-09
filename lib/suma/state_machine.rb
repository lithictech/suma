# frozen_string_literal: true

require "state_machines/error"
require "state_machines"

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

  def initialize(obj, name)
    @obj = obj
    @name = name
    @machine = @obj.class.state_machines[@name]
  end

  def current_state = @obj.send(@name)

  # @return [Array<Symbol>]
  def available_events = @machine.events.valid_for(@obj).map(&:name)
end
