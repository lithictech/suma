# frozen_string_literal: true

require "faker"

module Faker::Suma
  class << self
    def us_phone
      s = +"1"
      # First char is never 0 in US area codes
      s << Faker::Number.between(from: 1, to: 9).to_s
      Array.new(9) do
        s << Faker::Number.between(from: 0, to: 9).to_s
      end
      return s
    end

    def number(r)
      return Faker::Number.between(from: r.begin, to: r.end)
    end
  end
end
