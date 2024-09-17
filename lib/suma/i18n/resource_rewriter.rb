# frozen_string_literal: true

require "appydays/configurable"
require "csv"
require "fileutils"
require "nokogiri"
require "redcarpet"
require "sequel/sequel_translated_text"

require "suma"
require "suma/message"

# Processes normal resource strings into a frontend-readable format.
# Note the output file is JSON-based, but also as compact as possible.
# In the future we could move to a binary format but it's probably not worth it in terms of complexity for now.
class Suma::I18n::ResourceRewriter
  Formatter = Struct.new(:symbol, :weight)

  # The localized string can be used verbatim.
  FORMATTER_STR = Formatter.new(symbol: :s, weight: 10)
  # The localized string should be rendered with markdown.
  # There should usually be NO outer paragraph tag (see +FORMATTER_MD_MULTILINE+).
  #
  # Note that, if a localized string is plain (+FORMATTER_STR+),
  # but nests to another string (+KEY_LOCALIZE+) that uses +FORMATTER_MD+,
  # the 'nesting' outer string will also get a +FORMATTER_MD+.
  FORMATTER_MD = Formatter.new(symbol: :m, weight: 20)
  # The localized string should be rendered with markdown, WITH paragraph tags around each paragraph.
  FORMATTER_MD_MULTILINE = Formatter.new(symbol: :mp, weight: 30)

  def initialize
    # noinspection RubyArgCount
    @redcarpet = Redcarpet::Markdown.new(Redcarpet::Render::HTML.new)
    # As we process the hash, keep a map of the strings, to the $t nestings the string depends on.
    # Then in a second pass, we deeply resolve the nestings to find the right formatter.
    @nestings = NestingMap.new
  end

  def output_path_for(path)
    path = Pathname.new(path)
    purename = path.basename(".*")
    return path.parent + "out" + "#{purename}.out.json"
  end

  def to_output(resource_json_str)
    rstrings = Yajl::Parser.parse(resource_json_str)
    @nestings.clear
    # The first time, we fill up the translation nestings,
    # the second time, we can resolve them.
    # This could be a lot faster (we throw away most of what we do on the first pass)
    # but since this isn't a runtime method it isn't that important.
    self.process_hash(rstrings.deep_dup, path: [])
    result = self.process_hash(rstrings, path: [])
    return result
  end

  def formatter_for(s)
    s = s.strip
    md = @redcarpet.render(s)
    return FORMATTER_STR if md.blank? || md == "<p>#{s}</p>\n"
    return FORMATTER_MD_MULTILINE if s.include?("\n\n")
    return FORMATTER_MD
  end

  def process_hash(h, path:)
    h2 = h.each_with_object({}) do |(k, v), memo|
      full_path = path + [k]
      v2 = case v
        when Hash
          self.process_hash(v, path: full_path)
        when String
          self.process_string(full_path, v)
        else
          raise Suma::I18n::InvalidInput, "localization files should only have values of strings or hashes, got: #{v}"
      end
      memo[k] = v2
    end
    return h2
  end

  # Match and capture i18next-style interpolations using `{{ }}`, or translation nestings like $t("mykey").
  INTERPOLATOR_RE = /(\{\{[\w\s\-_:.,]+}}|\$t\([\w\s\-_:.]+\))/

  # The key naming the formatter function to apply. Ie, {"f": "sumaCurrency"} says
  # "apply the sumaCurrency formatter function to the given value".
  # Example i18next: {{amount, sumaCurrency}}
  KEY_FUNC = :f
  # The key naming the property to pull from the localization function argument.
  # For example, {"k":"amount"} with a JS localization call like `t("low_balance", {amount: account.balance})`
  # would grab the "amount" key from the passed parameter.
  # Example i18next: {{amount}}
  KEY_PROPERTY = :k
  # They key used when the localization string nests to another one.
  # For example, {"t":"low_balance"} calls JS to interpolate with the "low_balance" string.
  # Note this is exclusive with +KEY_FUNC+ and +KEY_PROPERTY+.
  # Example i18next: $t(low_balance)
  KEY_LOCALIZE = :t

  # String of low-value ASCII characters used for string replacement by the arguments in the output.
  # These strings should never appear in the resources.
  # Example i18next: "x {{y}}" => "x @%"
  PLACEHOLDER = "@%"
  PLACEHOLDER_BYTES = PLACEHOLDER.bytes

  def process_string(path, s)
    raise Suma::I18n::InvalidInput, "resource strings cannot contain #{PLACEHOLDER}" if s.include?(PLACEHOLDER)
    s = s.strip
    # Get the formatter for this 'naive' string. We'll do recursive nesting later.
    @nestings.put(path, self.formatter_for(s))
    cleaned_bytes = []
    args = []
    scanner = StringScanner.new(s)
    last_match_pos = 0
    sbytes = s.bytes
    while (scanned_bytes = scanner.skip_until(INTERPOLATOR_RE))
      cleaned_bytes.concat(sbytes[last_match_pos...(last_match_pos + scanned_bytes - scanner.matched_size)])
      cleaned_bytes.concat(PLACEHOLDER_BYTES)
      last_match_pos = scanner.pos
      if scanner.matched.start_with?("{{")
        # Turn {{x, y}} into {k: "x", f: "y"}
        parts = scanner.matched[2...-2].split(",").map(&:strip)
        arg = {KEY_PROPERTY => parts[0]}
        arg[KEY_FUNC] = parts[1] if parts.size > 1
        args << arg
      else
        # Turn $t(x) into {t: "x"}
        k = scanner.matched[3...-1]
        @nestings.add_dep(path, k)
        args << {KEY_LOCALIZE => k}
      end
    end
    cleaned_bytes.concat(last_match_pos.positive? ? sbytes[(last_match_pos)..] : scanner.string.bytes)
    formatter = @nestings.resolve_formatter(path)
    result = [formatter.symbol, cleaned_bytes.pack("C*").force_encoding("UTF-8")]
    result.insert(-1, *args)
    scanner.matched_size
    return result
  end

  class NestingMap
    def initialize
      @h = {}
    end

    def clear = @h.clear

    def get(path) = @h[self.key(path)]

    def put(path, formatter)
      key = self.key(path)
      @h[key] ||= Nesting.new(key, formatter)
    end

    def key(path) = path.is_a?(String) ? path : path.join(".")

    def add_dep(path, d) = self.get(path).dependencies << d

    def enumerate_nestings(path)
      n = self.get(path)
      # This could be done with an enumerator but this isn't a runtime method so no big deal.
      a = [n]
      n&.dependencies&.each do |d|
        a.concat(self.enumerate_nestings(d))
      end
      return a.compact
    end

    def resolve_formatter(path)
      fmt = self.get(path).formatter
      self.enumerate_nestings(path).each do |n|
        fmt = [fmt, n.formatter].max_by(&:weight)
      end
      return fmt
    end
  end

  class Nesting
    # @return [String]
    attr_reader :key
    # @return [Array<String>]
    attr_reader :dependencies
    # @return [Formatter]
    attr_accessor :formatter

    def initialize(key, formatter)
      @key = key
      @formatter = formatter
      @dependencies = []
    end
  end
end