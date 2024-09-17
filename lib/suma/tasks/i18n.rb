# frozen_string_literal: true

require "rake/tasklib"

require "suma/tasks"

class Suma::Tasks::I18n < Rake::TaskLib
  def initialize
    super
    namespace :i18n do
      desc "Reformat all locale JSON files to standard spacing, alphabetized keys, and formatter function."
      task :format do
        require "suma/i18n"
        Suma::I18n.reformat_files
        Suma::I18n.convert_source_to_resource_files
        Suma::I18n.rewrite_resource_files
      end

      desc "Ensure all locale files contain the same keys as the base language (en-us). " \
           "Return 0 if valid, print issues and return 1 if not."
      task :verify do
        require "suma/i18n"
        issues = Suma::I18n.verify_files
        next if issues.empty?
        issues.each do |iss|
          io << "locale: #{iss.locale_code}\n"
          io << "  missing:\n" if iss.missing
          iss.missing.each { |k| io << "    #{k}\n" }
          io << "  extra:\n" if iss.extra
          iss.extra.each { |k| io << "    #{k}\n" }
        end
        exit(1)
      end

      desc "Write to stdout the contents of a CSV file that should be used for translation. " \
           "Provide a source language and its strings will be merged with the base language (en, es, etc)."
      task :prepare_csv, [:locale_code] do |_, args|
        require "suma/i18n"
        lang = args[:locale_code] || Suma::I18n.base_locale_code
        Suma::I18n.prepare_csv(lang, output: io)
      end

      desc "Read from stdin the contents of a CSV file containing translated strings (see prepare_csv). " \
           "It is written to the strings.json file of the provided locale."
      task :import_csv do
        require "suma/i18n"
        Suma::I18n.import_csv(input: $stdin)
      end

      desc "Write to stdout the English strings of the localized content table."
      task :export_dynamic do
        require "suma/i18n"
        Suma::I18n.export_dynamic(output: io)
      end

      desc "Read from stdin a CSV of the format from export_dynamic, " \
           "and upsert the data into the localized content table."
      task :import_dynamic do
        require "suma/i18n"
        Suma::I18n.import_dynamic(input: $stdin)
      end
    end
  end

  def io
    return $stdout
  end
end
