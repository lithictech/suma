# frozen_string_literal: true

require "rake/tasklib"

require "suma/tasks"

class Suma::Tasks::Annotate < Rake::TaskLib
  def initialize
    super
    desc "Update model annotations"
    task :annotate do
      unless `git diff`.blank?
        puts "Cannot annotate while there is any git diff."
        puts "Please commit or revert any diff and try again."
        exit(1)
      end

      require "suma"
      Suma.load_app
      files = []
      Suma::Postgres.model_classes.each do |cls|
        next unless cls.name
        filename = cls.name.underscore
        files << "lib/#{filename}.rb" if cls.name
      end

      require "sequel/annotate"
      Sequel::Annotate.annotate(files, border: true)
      puts "Finished annotating:"
      files.each { |f| puts "  #{f}" }
      puts "Please commit the changes."
    end
  end
end
