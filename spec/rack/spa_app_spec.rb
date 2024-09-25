# frozen_string_literal: true

require "rack/spa_app"

RSpec.describe Rack::SpaApp do
  it "sets up the dependencies and runs the app" do
    app = Rack::Builder.new do |bld|
      Rack::SpaApp.run_spa_app(bld, Dir.pwd)
    end
    app.call({})
  end
end
