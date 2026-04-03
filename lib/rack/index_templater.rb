# frozen_string_literal: true

require "erb"
require "rack"

# Use ERB to replace strings in index.html with values at runtime.
class Rack::IndexTemplater
  BACKUP_SUFFIX = ".indextemplater_original"

  def initialize(index_html_path, backup_suffix: BACKUP_SUFFIX)
    @index_html_path = index_html_path
    @index_html_backup = index_html_path + backup_suffix
  end

  def emplace(replacements)
    self.prepare
    File.open(@index_html_backup) do |f|
      tmpl = ERB.new(f.read)
      result = tmpl.result_with_hash(replacements)
      File.write(@index_html_path, result)
    end
  end

  protected def prepare
    return if File.exist?(@index_html_backup)
    FileUtils.move(@index_html_path, @index_html_backup)
  end
end
