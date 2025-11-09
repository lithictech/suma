# frozen_string_literal: true

require "rake/tasklib"

require "suma/tasks"

class Suma::Tasks::Annotate < Rake::TaskLib
  def initialize
    super
    desc "Update model annotations"
    task :annotate do
      unless Kernel.send(:`, "git diff").blank?
        puts "Cannot annotate while there is any git diff."
        puts "Please commit or revert any diff and try again."
        next Kernel.exit(1)
      end

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
  end
end
