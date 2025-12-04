# frozen_string_literal: true

class Suma::NamedValue < Suma::TypedStruct
  # @return [String]
  attr_reader :name
  # @return [String]
  attr_reader :value
end
