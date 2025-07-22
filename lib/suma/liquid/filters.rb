# frozen_string_literal: true

require "liquid"
require "suma"

module Suma::Liquid::Filters
  def humanize(input)
    return input.humanize
  end

  def money(input)
    return input.format
  end
end

Liquid::Environment.default.register_filter(Suma::Liquid::Filters)
