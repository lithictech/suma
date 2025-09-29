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

        desc "Sync Lime trips from a CSV report on STDIN or passed as a filename. " \
             "If no STDIN or filename, sync reports from the database."
        task :limereport do
          require "suma"
          Suma.load_app?
          require "suma/lime/sync_trips_from_report"
          ARGV.shift
          io = Suma::Rakeutil.readall_nonblock(ARGF)
          raise "Must pass a filename or use STDIN" if io.nil?
          Suma::Lime::SyncTripsFromReport.new.run_for_report(io)
        end
      end
    end
  end
end
