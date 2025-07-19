# frozen_string_literal: true

require "suma/i18n/formatter"

# Processes normal resource strings into a frontend-readable format.
# Note the output file is JSON-based, but also as compact as possible.
# In the future we could move to a binary forma,  but it's probably not worth it in terms of complexity for now.
class Suma::I18n::ResourceRewriter
  def initialize
    # As we process the hash, keep a map of the strings, to the $t nestings the string depends on.
    # Then in a second pass, we deeply resolve the nestings to find the right formatter.
    @nestings = NestingMap.new
    @primed ||= {}
  end

  # The first time, we fill up the translation nestings,
  # the second time, we can resolve them.
  # This could be a lot faster (we throw away most of what we do on the first pass)
  # but since this isn't a runtime method it isn't that important.
  def prime(*resource_files)
    resource_files.each do |rf|
      self._to_output(rf)
      @primed[rf.namespace] = true
    end
  end

  # Return the output for a resource file.
  def to_output(resource_file)
    raise Suma::InvalidPrecondition, "Must call #prime with '#{resource_file.namespace}' resource file" unless
      @primed.key?(resource_file.namespace)
    return self._to_output(resource_file)
  end

  def _to_output(resource_file)
    result = self.process_hash(resource_file.strings, path: [resource_file.namespace])
    return result
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
    @nestings.put(path, Suma::I18n::Formatter.for(s))
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

  # Represent a resource file, like 'strings.json'.
  # +str+ is the contents of the resource file, which will be parsed as json.
  class ResourceFile
    # Namespace ('strings' for 'strings.json').
    attr_accessor :namespace
    # Parsed contents of the input string.
    attr_accessor :strings

    def initialize(strings, namespace:)
      @strings = strings
      @namespace = namespace
    end
  end
end
