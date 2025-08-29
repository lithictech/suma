# frozen_string_literal: true

require "suma" unless defined?(Suma)

module Suma::Enumerable
  module_function def group_and_count_by(enumerable)
    result = Hash.new(0)
    enumerable.each do |item|
      key = yield(item)
      result[key] += 1
    end
    return result
  end

  module_function def group_and_count(enumerable)
    return group_and_count_by(enumerable) { |k| k }
  end

  # Return the only item in the enumerable if it has a length one.
  # Raise an ArgumentError otherwise.
  module_function def one!(enumerable)
    return enumerable.first if enumerable.length == 1
    raise ArgumentError, "must have exactly 1 item, got #{enumerable.count}"
  end
end
