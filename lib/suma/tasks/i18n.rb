# frozen_string_literal: true

require "rake/tasklib"

require "suma/tasks"

class Suma::Tasks::I18n < Rake::TaskLib
  def initialize
    super
    namespace :i18n do
      desc "Import static_string_keys into the database."
      task :import_static_string_keys do
        Suma.load_app?
        Suma::I18n::StaticString.import_all_namespaces
      end

      desc "Import seeds into the database."
      task :import do
        Suma.load_app?
        Suma::I18n.import_seeds
      end

      desc "Export seeds from the database."
      task :export do
        Suma.load_app?
        Suma::I18n.export_seeds
      end
    end
  end
end
