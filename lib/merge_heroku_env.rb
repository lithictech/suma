# frozen_string_literal: true

module MergeHerokuEnv
  def self.merge(env=ENV)
    if (heroku_app = env.fetch("MERGE_HEROKU_ENV", nil))
      text = Kernel.send(:`, "heroku config -j --app=#{heroku_app}")
      env.merge!(Yajl::Parser.parse(text))
    end
  end
end

MergeHerokuEnv.merge
