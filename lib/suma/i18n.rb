# frozen_string_literal: true

require "csv"
require "fileutils"
require "nokogiri"
require "appydays/configurable"
require "sequel/sequel_translated_text"

require "suma"
require "suma/message"

module Suma::I18n
  include Appydays::Configurable

  class InvalidInput < StandardError; end

  LOCALE_DIR = Suma::DATA_DIR.parent + "webapp/public/locale"
  Locale = Struct.new(:code, :language, :native)
  SUPPORTED_LOCALES = {
    "en" => Locale.new("en", "English", "English"),
    "es" => Locale.new("es", "Spanish", "Español"),
  }.freeze
  MESSAGE_PREFIX = "message:"

  class << self
    attr_reader :enabled_locales

    @enabled_locales = []
  end

  configurable(:i18n) do
    setting :base_locale_code, "en"
    setting :enabled_locale_codes, ["en", "es"], convert: ->(s) { s.split }

    after_configured do
      @enabled_locales = self.enabled_locale_codes.map { |c| SUPPORTED_LOCALES.fetch(c) }
      SequelTranslatedText.default_language = self.base_locale_code
    end
  end

  def self.reformat_files
    Dir.glob(LOCALE_DIR + "**/*.json") do |path|
      self.reformat_file(path)
    end
  end

  def self.reformat_file(path)
    h = Yajl::Parser.parse(File.open(path))
    clean = self.replace_entities(h)
    so = self.sort_hash(clean)
    File.write(path, JSON.pretty_generate(so))
  end

  def self.replace_entities(h)
    h2 = h.to_h
    h2.transform_values! do |value|
      case value
        when Hash
          self.replace_entities(value)
        when String, nil
          self._clean_str(value)
        else
          value
      end
    end
    return h2
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
    base_keys = self.flatten_hash(self.base_locale_data).keys.to_set
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

  def self.base_locale_data
    return self.strings_data(self.base_locale_code)
  end

  # @return [String]
  def self.strings_path(locale_code)
    return LOCALE_DIR + locale_code + "strings.json"
  end

  def self.strings_data(locale_code)
    begin
      d = File.read(self.strings_path(locale_code))
    rescue Errno::ENOENT
      return {}
    end
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

  # Ensures that both strings interpolation values match
  # and remove whitespace. Strings should have same amount of
  # dynamic values. Values can be in reversed order e.g.
  #   es string: `{{xyz}} es {{ zyx }}`
  #   en string: `{{ zyx }} en {{xyz}}`
  #   Returns es string: `{{xyz}} es {{zyx}}`
  # @return [String]
  def self.ensure_interpolation_values_match(str, other_str, base_lng="English")
    return str unless base_lng === "English"
    if (sc = str.scan("{{").count) != (osc = other_str.scan("{{").count)
      raise InvalidInput, "Dynamic value count should be #{osc} but is #{sc}:\n#{str}"
    end
    dynamic_vals = []
    other_dynamic_vals = []
    str.split("{{").drop(1).each_with_index do |int_string, idx|
      dynamic_vals << int_string.split("}}").first
      other_dynamic_vals << other_str.split("{{")[idx + 1].split("}}").first.strip
    end
    return str if dynamic_vals.empty?

    dynamic_vals.each do |val|
      vs = val.strip
      unless other_dynamic_vals.include?(vs)
        raise InvalidInput,
              "#{vs} does not match dynamic values: #{other_dynamic_vals.join(', ')}"
      end
      str = str.sub(val, vs)
    end
    return str
  end

  def self.prepare_csv(locale_code, output:)
    base_locale = SUPPORTED_LOCALES.fetch(self.base_locale_code)
    locale = SUPPORTED_LOCALES.fetch(locale_code)
    base_data = self.flatten_hash(self.base_locale_data)
    locale_data = self.flatten_hash(self.strings_data(locale.code))
    base_messages = self.load_messages(self.base_locale_code)
    locale_messages = self.load_messages(locale.code)
    CSV(output) do |csv|
      csv << ["Key", locale.language, base_locale.language]
      base_data.sort.each do |(key, base_str)|
        csv << [key, self._clean_str(locale_data[key]), self._clean_str(base_str)]
      end
      base_messages.each do |(key, base_contents)|
        csv << [key, self._clean_str(locale_messages[key]), self._clean_str(base_contents)]
      end
    end
  end

  def self._clean_str(s)
    return nil if s.nil?
    return Nokogiri::HTML5.parse(s).text
  end

  def self.load_messages(locale_code)
    templates = {}
    Dir[Suma::Message::DATA_DIR + "**/*.#{locale_code}.*.liquid"].map do |s|
      next if s.include?("/specs/")
      tmplname, _, transport, _ = File.basename(s).split(".")
      tmplpath = File.dirname(s.delete_prefix(Suma::Message::DATA_DIR.to_s))
      key = "#{MESSAGE_PREFIX}#{tmplpath}/#{tmplname}.#{transport}"
      templates[key] = File.read(s)
    end
    return templates
  end

  def self.import_csv(input:)
    lines = CSV.new(input).to_a
    _key_header, language, base_language = lines.shift
    locale = SUPPORTED_LOCALES.values.find { |loc| loc.language == language } or
      raise "#{language} is not supported"
    hsh = {}
    lines.each do |line|
      key, str, other_str = line
      next self.import_message(locale.code, key, str) if key.start_with?(MESSAGE_PREFIX)
      # Add intermediate hashes along the path, then set the value at the end
      tip = hsh
      pathparts = key.split(":")
      pathparts[...-1].each do |pathpart|
        tip[pathpart] ||= {}
        tip = tip[pathpart]
      end
      tip[pathparts.last] = self.ensure_interpolation_values_match(str, other_str, base_language) unless str.blank?
    end
    so = self.sort_hash(hsh)
    File.write(self.strings_path(locale.code), JSON.pretty_generate(so))
  end

  def self.import_message(locale_code, key, contents)
    transport_sep = key.rindex(".")
    transport = key[(transport_sep + 1)..]
    partial_path = key[MESSAGE_PREFIX.length...transport_sep].delete_prefix("/")
    path = Suma::Message::DATA_DIR + "#{partial_path}.#{locale_code}.#{transport}.liquid"
    FileUtils.mkpath(File.dirname(path))
    File.write(path, contents)
  end

  DYNAMIC_DB_COLUMNS = [:id, :en, :es].freeze
  DYNAMIC_CSV_COLUMNS = ["Id", "English", "Spanish"].freeze

  def self.export_dynamic(output:)
    CSV(output) do |csv|
      ds = Suma::TranslatedText.dataset.select(*DYNAMIC_DB_COLUMNS)
      csv << DYNAMIC_CSV_COLUMNS
      ds.naked.paged_each do |row|
        csv << DYNAMIC_DB_COLUMNS.map { |k| row.fetch(k) }
      end
    end
  end

  def self.import_dynamic(input:)
    validated = false
    linecount = 0
    ds = Suma::TranslatedText.dataset
    ddl_columns = DYNAMIC_DB_COLUMNS.drop(1).map { |c| "#{c} TEXT" }.join(", ")
    temp_table = :i18nimport
    chunk = []
    ds.db.transaction do
      ds.db << "CREATE TEMP TABLE #{temp_table}(id INTEGER, #{ddl_columns})"
      CSV.parse(input, headers: false) do |line|
        unless validated
          raise InvalidInput, "Headers should be: #{DYNAMIC_CSV_COLUMNS.join(',')}" unless line == DYNAMIC_CSV_COLUMNS
          validated = true
          next
        end
        linecount += 1
        chunk << line
        if chunk.size > 500
          ds.db[temp_table].import(DYNAMIC_DB_COLUMNS, chunk)
          chunk.clear
        end
      end
      ds.db[temp_table].import(DYNAMIC_DB_COLUMNS, chunk) unless chunk.empty?
      update_col_stmts = DYNAMIC_DB_COLUMNS.map { |c| "#{c} = t.#{c}" }.join(", ")
      update_stmt = <<~SQL
        UPDATE #{Suma::TranslatedText.table_name} SET #{update_col_stmts}
        FROM (SELECT * FROM #{temp_table}) t
        WHERE #{Suma::TranslatedText.table_name}.id = t.id;
      SQL
      updated = ds.db.execute(update_stmt)
      raise InvalidInput, "CSV had #{linecount} rows but only matched #{updated} database rows" unless
        updated == linecount
    end
  end

  # Some strings are kept in raw markdown files in /source,
  # so we can easily localize and render full pages of markdown.
  # This converts them into dedicated string resource files.
  def self.convert_source_to_resource_files
    Dir.glob(LOCALE_DIR + "**/source/*.md") do |path|
      md = File.read(path)
      src_start_idx = path.rindex("/source/")
      basename = File.basename(path)[...-3]
      newpath = path[..src_start_idx] + basename + ".json"

      contents = Yajl::Encoder.encode({contents: md}, pretty: true, indent: "  ")

      File.write(newpath, contents)
    end
  end
end
