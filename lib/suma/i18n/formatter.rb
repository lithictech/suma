# frozen_string_literal: true

require "redcarpet"

require "suma/i18n"
require "suma/lru"

# Describe an internationalization formatter.
class Suma::I18n::Formatter
  # Shorthand to indicate the formatter in static resource files.
  # The frontend looks for this symbol to determine what component to use.
  # @!attribute symbol
  attr_reader :symbol

  # Used to resolve the writer where strings are nested (like "xyz $(abc)" in static files).
  # Higher weights have higher priority.
  # @!attribute weight
  attr_reader :weight

  # The zero-width characters that are prepended inside `expose_translated` to indicate the formatter.
  # The frontend looks for this string to determine what component to use, similar to +symbol+.
  # See https://blog.bitsrc.io/how-to-hide-secrets-in-strings-modern-text-hiding-in-javascript-613a9faa5787
  # for some examples of zero-width characters.
  attr_reader :flag

  def initialize(symbol:, weight:, flag:)
    @symbol = symbol
    @weight = weight
    @flag = flag
  end

  # The localized string can be used verbatim.
  STR = self.new(symbol: :s, weight: 10, flag: "")
  # The localized string should be rendered with markdown.
  # There should usually be NO outer paragraph tag (see +MD_MULTILINE+).
  #
  # Note that, if a localized string is plain (+STR+),
  # but nests to another string (see +Suma::I18n::ResourceRewriter::KEY_LOCALIZE+) that uses +MD+,
  # the 'nesting' outer string will also get a +MD+.
  MD = self.new(symbol: :m, weight: 20, flag: "\u200C")

  # The localized string should be rendered with markdown, WITH paragraph tags around each paragraph.
  MD_MULTILINE = self.new(symbol: :mp, weight: 30, flag: "\u200D")

  class << self
    # Return a global HTML redcarpet instance.
    def redcarpet
      # noinspection RubyArgCount
      return @redcarpet ||= Redcarpet::Markdown.new(Redcarpet::Render::HTML.new)
    end

    # @param s [String]
    # @return [Formatter]
    def for(s)
      s = s.strip
      hash = s.hash
      if (cached = self.lru[hash])
        return cached
      end
      md = self.redcarpet.render(s)
      fmt = if md.blank? || md == "<p>#{s}</p>\n"
              STR
      elsif s.include?("\n\n") || md.match?(/<(div|ul|ol)>/)
        MD_MULTILINE
      else
        MD
      end
      self.lru[hash] = fmt
      return fmt
    end

    def lru
      return @lru ||= Suma::Lru.new(300)
    end
  end
end
