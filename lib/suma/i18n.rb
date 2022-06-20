# frozen_string_literal: true

require "csv"
require "appydays/configurable"

require "suma"

module Suma::I18n
  include Appydays::Configurable

  LOCALE_DIR = Suma::DATA_DIR.parent + "webapp/public/locale"
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
    setting :base_locale_code, "en"
    setting :enabled_locale_codes, ["en", "es"], convert: ->(s) { s.split }

    after_configured do
      @enabled_locales = self.enabled_locale_codes.map { |c| SUPPORTED_LOCALES.fetch(c) }
    end
  end

  def self.reformat_files
    Dir.glob(LOCALE_DIR + "**/*.json") do |path|
      self.reformat_file(path)
    end
  end

  def self.reformat_file(path)
    h = Yajl::Parser.parse(File.open(path))
    so = self.sort_hash(h)
    File.write(path, JSON.pretty_generate(so))
  end

  def self.sort_hash(h)
    h2 = h.sort.to_h
    h2.transform_values! do |value|
      next value unless value.is_a?(Hash)
      self.sort_hash(value)
    end
    return h2
  end

  VerificationIssue = Struct.new(:locale_code, :missing, :extra)

  # @return [Array<VerificationIssue>]
  def self.verify_files
    base_keys = self.flatten_hash(self.strings_data(self.base_locale_code)).keys.to_set
    result = []
    SUPPORTED_LOCALES.each_value do |locale|
      next if locale.code == self.base_locale_code
      locale_keys = self.flatten_hash(self.strings_data(locale.code)).keys.to_set
      extra = (locale_keys - base_keys).sort
      missing = (base_keys - locale_keys).sort
      next if extra.empty? && missing.empty?
      result << VerificationIssue.new(locale.code, missing, extra)
    end
    return result
  end

  # @return [String]
  def self.strings_path(locale_code)
    return LOCALE_DIR + locale_code + "strings.json"
  end

  def self.strings_data(locale_code)
    d = File.read(self.strings_path(locale_code))
    return Yajl::Parser.parse(d)
  end

  # Turn a nested nested hash like {a: {b: 1}, c: 2} into
  # a flat one like {a.b: 1, c: 2}
  # @return [Hash]
  def self.flatten_hash(h, memo: {}, path: [])
    h.each do |k, v|
      kpath = path + [k]
      if v.is_a?(Hash)
        self.flatten_hash(v, memo:, path: kpath)
      else
        memo[kpath.join(":")] = v
      end
    end
    return memo
  end

  def self.prepare_csv(locale_code, output:)
    base_locale = SUPPORTED_LOCALES.fetch(self.base_locale_code)
    locale = SUPPORTED_LOCALES.fetch(locale_code)
    base_data = self.flatten_hash(self.strings_data(base_locale.code))
    locale_data = self.flatten_hash(self.strings_data(locale.code))
    CSV(output) do |csv|
      csv << ["Key", locale.language, base_locale.language]
      base_data.sort.each do |(key, base_str)|
        csv << [key, locale_data[key], base_str]
      end
    end
  end

  def self.import_csv(input:)
    lines = CSV.new(input).to_a
    _key_header, language, _base_language = lines.shift
    locale = SUPPORTED_LOCALES.values.find { |loc| loc.language == language } or
      raise "#{language} is not supported"
    hsh = {}
    lines.each do |line|
      key, str, _ = line
      # Add intermediate hashes along the path, then set the value at the end
      tip = hsh
      pathparts = key.split(":")
      pathparts[...-1].each do |pathpart|
        tip[pathpart] ||= {}
        tip = tip[pathpart]
      end
      tip[pathparts.last] = str unless str.blank?
    end
    so = self.sort_hash(hsh)
    File.write(self.strings_path(locale.code), JSON.pretty_generate(so))
  end
end
