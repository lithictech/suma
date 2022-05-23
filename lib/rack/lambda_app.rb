# frozen_string_literal: true

require "rack"

# Call the inner proc as the app.
# If proc returns nil, keep calling middleware;
# if proc returns a result, return it.
class Rack::LambdaApp
  # LambdaApp.new returns itself, which has a +new+ method so it can
  # be used like normal middleware.
  def initialize(proc)
    @proc = proc
  end

  def new(app)
    @app = app
  end

  def call(env)
    result = proc.call(env)
    return result if result
    return @app.call(env)
  end
end
