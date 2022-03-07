# frozen_string_literal: true

require "rake/tasklib"

require "suma/tasks"

class Suma::Tasks::Heroku < Rake::TaskLib
  def initialize
    super()
    namespace :heroku do
      desc "Post to Slack if the number of dynos is not what is expected"
      task :check_dynos do
        require "suma/heroku"
        require "suma/slack"
        heroku = Suma::Heroku.client
        info = heroku.formation.info Suma::Heroku.app_name, "web"
        if info["quantity"] != Suma::Heroku.target_web_dynos
          notifier = Suma::Slack.new_notifier(
            channel: "#techops",
            username: "Monitor Bot",
            icon_emoji: ":hourglass_flowing_sand:",
          )
          notifier.post(
            text: "Heroku web dynos are scaled to #{info['quantity']}, expected #{Suma::Heroku.target_web_dynos}",
          )
        end
      end
    end
  end
end
