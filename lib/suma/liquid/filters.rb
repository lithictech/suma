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

  def card(input)
    return "#{input.brand} ending in #{input.last4}"
  end
end

Liquid::Template.register_filter(Suma::Liquid::Filters)
