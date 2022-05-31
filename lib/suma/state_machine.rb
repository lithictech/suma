# frozen_string_literal: true

require "suma"

module Suma::StateMachine
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
end
