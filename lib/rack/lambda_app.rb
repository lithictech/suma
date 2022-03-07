# frozen_string_literal: true

require "rack"

class Rack::LambdaApp
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
