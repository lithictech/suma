# frozen_string_literal: true

require "rake/tasklib"

require "suma/tasks"

class Suma::Tasks::Annotate < Rake::TaskLib
  def initialize
    super
    desc "Update all annotations derived from source code."
    task :annotate do
      Rake::Task["annotate:check"].invoke
      Rake::Task["annotate:db"].invoke
      Rake::Task["annotate:adminapp"].invoke
      Rake::Task["annotate:webapp"].invoke
    end

    namespace :annotate do
      desc "Check there are no git diffs."
      task :check do
        unless Kernel.send(:`, "git diff").blank?
          puts "Cannot annotate while there is any git diff."
          puts "Please commit or revert any diff and try again."
          next Kernel.exit(1)
        end
      end

      desc "Update model annotations."
      task :db do
        # See https://github.com/jeremyevans/sequel-annotate/discussions/24
        # for why we have this (temporary?) workaround.
        ENV["SEQUEL_ANNOTATE_HACK"] = "1"
        begin
          require "suma"
          Suma.load_app?
        ensure
          ENV.delete("SEQUEL_ANNOTATE_HACK")
        end
        files = []
        Suma::Postgres.each_model_class do |cls|
          next if cls.anonymous?
          filename = cls.name.underscore
          files << "lib/#{filename}.rb" if cls.name
        end

        require "sequel/annotate"
        Sequel::Annotate.annotate(files, border: true)
        puts "Finished annotating #{files.count} model files."
        files.each { |f| puts "  #{f}" }
        puts "Please commit the changes."
      end

      desc "Update admin JSDoc typedefs."
      task :adminapp do
        require "suma"
        Suma.load_app?
        require "suma/apps"
        require "suma/service/entity_jsdoc_writer"
        classes = Suma::Service::EntityJsdocWriter.gather_entity_classes(prefix: "Suma::AdminAPI::")
        s = Suma::Service::EntityJsdocWriter.new.build(classes, extra: Suma::Service::EntityJsdocWriter::ADMIN_EXTRA)
        self.class.write_typedefs(Suma::SELF_DIR + "adminapp/src/typedefs.js", s)
      end

      desc "Update webapp JSDoc typedefs."
      task :webapp do
        require "suma"
        Suma.load_app?
        require "suma/apps"
        require "suma/service/entity_jsdoc_writer"
        classes = Suma::Service::EntityJsdocWriter.gather_entity_classes(prefix: "Suma::API::")
        s = Suma::Service::EntityJsdocWriter.new.build(classes)
        self.class.write_typedefs(Suma::SELF_DIR + "webapp/src/typedefs.js", s)
      end
    end
  end

  class << self
    def write_typedefs(path, s)
      File.write(path, s)
    end
  end
end
