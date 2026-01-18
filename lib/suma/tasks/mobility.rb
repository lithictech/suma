# frozen_string_literal: true

require "rake/tasklib"

require "suma"
require "suma/rakeutil"

class Suma::Tasks::Mobility < Rake::TaskLib
  def initialize
    super
    namespace :mobility do
      namespace :sync do
        desc "Run the LyftPass sync."
        task :lyftpass do
          require "suma"
          Suma.load_app?
          require "suma/lyft/pass"
          lp = Suma::Lyft::Pass.from_config
          lp.authenticate
          Suma::Lyft::Pass.programs_dataset.each do |program|
            lp.sync_trips_from_program(program)
          end
        end

        desc <<~DESC
          Sync Lime trips from a CSV, which can come from one of a variety of sources:

          - STDIN,
          - A filename, passed as 'task[filename]' (task argument) or 'task filename' (Ruby ARGF),
          - 'task[redis://keyname]', where 'keyname' is the redis key containing the CSV.
            To set this value, you usually want to use something like:
              `Sidekiq.redis { |c| c.set('temptripsync', File.read(filename), ex: 60*10) }`
            to make sure the key expires after a few minutes.
          - Use no arguments or stdin to launch a sync like the async job does (from the WebhookDB DB).
        DESC
        task :limereport, [:filename] do |_, args|
          require "suma"
          Suma.load_app?

          require "suma/lime/sync_trips_from_report"
          report_txt = Suma::Rakeutil.readfile(args)
          if report_txt.nil?
            Suma::Lime::SyncTripsFromReport.new.run
          else
            Suma::Lime::SyncTripsFromReport.new.run_for_report(report_txt)
          end
        end
      end
    end
  end
end
