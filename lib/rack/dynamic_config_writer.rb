# frozen_string_literal: true

require "rack"
require "nokogiri"

# Allow dynamic configuration of a SPA.
# When the backend app starts up, it should run #emplace.
# This will 1) copy the index.html to a 'backup' location
# if it does not exist, 2) replace a placeholder string
# in the index.html with the given keys and values
# (use .pick_env_vars to pull everything like 'REACT_APP_'),
# and write it out to index.html.
#
# IMPORTANT: This sort of dynamic config writing is not normal
# for SPAs so needs some further explanation.
# The build process should be exactly the same;
# for example, you'd still run `npm run build`,
# and generate a totally normal build output.
# It's the *backend* running that modifies index.html
# (and creates index.html.original) *at backend startup*,
# not at build time.
class Rack::DynamicConfigWriter
  GLOBAL_ASSIGN = "window.rackDynamicConfig"
  BACKUP_SUFFIX = ".original"

  def initialize(
    index_html_path,
    global_assign: GLOBAL_ASSIGN,
    backup_suffix: BACKUP_SUFFIX
  )
    @index_html_path = index_html_path
    @global_assign = global_assign
    @index_html_backup = index_html_path + backup_suffix
  end

  def emplace(keys_and_values)
    self.prepare
    json = Yajl::Encoder.encode(keys_and_values)
    script = "#{@global_assign}=#{json}"
    File.open(@index_html_backup) do |f|
      doc = Nokogiri::HTML5(f)
      doc.at("head").prepend_child("<script>#{script}</script>")
      File.write(@index_html_path, doc.serialize)
    end
    return script
  end

  protected def prepare
    return if File.exist?(@index_html_backup)
    FileUtils.move(@index_html_path, @index_html_backup)
  end

  def self.pick_env(regex_or_prefix, env=ENV)
    return env.to_a.select { |(k, _v)| k.start_with?(regex_or_prefix) }.to_h if regex_or_prefix.is_a?(String)
    return env.to_a.select { |(k, _v)| regex_or_prefix.match?(k) }.to_h
  end
end
