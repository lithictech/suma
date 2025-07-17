# frozen_string_literal: true

require "appydays/configurable"
require "fileutils"

require "suma"
require "suma/message"

module Suma::I18n
  include Appydays::Configurable

  class InvalidInput < StandardError; end

  DATA_DIR = Suma::DATA_DIR + "i18n"
  Locale = Struct.new(:code, :language, :native)
  SUPPORTED_LOCALES = {
    "en" => Locale.new("en", "English", "English"),
    "es" => Locale.new("es", "Spanish", "Español"),
  }.freeze

  class << self
    attr_reader :enabled_locales

    @enabled_locales = []
  end

  configurable(:i18n) do
    # What locale should be used for fallback?
    setting :base_locale_code, "en"
    # What namespace is the 'base' namespace for global things like form text, errors, etc?
    setting :base_namespace, "strings"
    # Use this to disable certain locales. Used when dynamic resources or static strings
    # are not being localized to all supported locales.
    setting :enabled_locale_codes, ["en", "es"], convert: lambda(&:split)
    # How often do we check for new static strings?
    # Changes to static strings may take this long to show up in the UI, if not picked up through pub/sub.
    setting :static_string_rebuild_interval, 300

    after_configured do
      @enabled_locales = self.enabled_locale_codes.map { |c| SUPPORTED_LOCALES.fetch(c) }
      SequelTranslatedText.default_language = self.base_locale_code
    end
  end

  class << self
    # What error codes are found in the base localization strings?
    def localized_error_codes
      return @localized_error_codes ||= begin
        keys = Suma::I18n::StaticStringIO.load_keys_from_file(Suma::I18n::StaticStringIO.static_keys_base_file)
        keys.select { |k| k.start_with?("errors.") }.map { |k| k[7..] }
      end
    end

    # Turn a nested nested hash like {a: {b: 1}, c: 2} into
    # a flat one like {a.b: 1, c: 2}
    # @return [Hash]
    def flatten_hash(h, memo: {}, path: [])
      h.each do |k, v|
        kpath = path + [k]
        if v.is_a?(Hash)
          self.flatten_hash(v, memo:, path: kpath)
        else
          memo[kpath.join(".")] = v
        end
      end
      return memo
    end
  end

  # Hash where missing keys mutate the receiver to add a missing hash,
  # allowing things like `h[x][y][z] = 1`.
  class AutoHash < Hash
    def initialize(*)
      super
      self.default_proc = proc { |h, k| h[k] = AutoHash.new }
    end
  end
end

require "suma/i18n/formatter"
require "suma/i18n/resource_rewriter"
require "suma/i18n/static_string_io"
require "suma/i18n/static_string_rebuilder"
