# frozen_string_literal: true

require "liquid"

require "suma"

# Allow members to expose variables from a template
# using custom blocks and registers.
# See https://github.com/Shopify/liquid/wiki/Liquid-for-Programmers#create-your-own-tag-blocks
# for more info about blocks.
# See https://github.com/Shopify/liquid/wiki/Liquid-for-Programmers#difference-between-assigns-and-registers
# for info about "registers", which are used as template-render-specific mutable state
# (so we can mutate it in the tag/block, then inspect the mutated value after-the-fact).
class Suma::Liquid::Expose < Liquid::Block
  def initialize(tag_name, var_name, options)
    super
    @var_name = var_name.strip.to_sym
  end

  def render(context)
    content = super
    exposed = context.registers[:exposed]
    raise TypeError, "Must set `template.registers[:exposed] = {}` to use this tag" if exposed.nil?
    context.registers[:exposed][@var_name] = content
    ""
  end
end

Liquid::Environment.default.register_tag("expose", Suma::Liquid::Expose)
