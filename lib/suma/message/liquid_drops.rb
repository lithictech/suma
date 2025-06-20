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
      return @recipient.member&.name
    end
  end

  class EnvironmentDrop < Liquid::Drop
    def name
      return Suma::RACK_ENV
    end
  end
end
