# frozen_string_literal: true

require "merge_heroku_env"

RSpec.describe MergeHerokuEnv do
  let(:env) { {} }
  it "merges config from Heroku into env if defined" do
    env["MERGE_HEROKU_ENV"] = "sushi"
    expect(Kernel).to receive(:`).with("heroku config -j --app=sushi").and_return('{"XYZ":"val"}')
    MergeHerokuEnv.merge(env)
    expect(env).to include("XYZ" => "val")
  end

  it "noops if not defined" do
    expect(Kernel).to_not receive(:`)
    MergeHerokuEnv.merge(env)
    expect(env).to_not include("XYZ")
  end
end
