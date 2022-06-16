# frozen_string_literal: true

module Suma::Message
  class MemberDrop < Liquid::Drop
    def initialize(recipient)
      @recipient = recipient
      super()
    end

    def to
      return @recipient.to
    end

    def name
      return @recipient.customer&.name
    end

    def greeting
      return nil unless @recipient.customer
      return @recipient.customer.greeting
    end
  end

  class EnvironmentDrop < Liquid::Drop
    def name
      return Suma::RACK_ENV
    end
  end
end
