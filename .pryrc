# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "appydays/dotenviable"
Appydays::Dotenviable.load

require "suma"
require "pry-clipboard"

Pry.config.commands.alias_command "ch", "copy-history"
Pry.config.commands.alias_command "cr", "copy-result"

# Decode the given cookie string. Since cookies are encrypted,
# this is useful for debugging what they contain.
def decode_cookie(s)
  require "suma/service"
  return Suma::Service.decode_cookie(s)
end

# Connect this session of Pry to the database.
# It also registers subscribers, so changes to the models are handled
# by their correct async jobs (since async jobs are handled in-process).
def connect
  return false if defined?(Suma::Role) # Do not double-load
  require "suma"
  Suma.load_app?
  require "suma/async"
  Suma::Async.setup_web
  return true
end

# Load models and fixtures. Use this when riffing locally.
def repl
  connect
  require "suma/fixtures"
  Suma::Fixtures.load_all
  return true
end

def viewhtml(s)
  md5 = Digest::MD5.hexdigest(s)
  path = Pathname(Dir.mktmpdir("viewhtml")).join("#{md5}.html").to_s
  File.write(path, s)
  `open #{path}`
end
