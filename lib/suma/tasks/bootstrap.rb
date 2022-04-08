# frozen_string_literal: true

require "rake/tasklib"

require "suma/tasks"

class Suma::Tasks::Bootstrap < Rake::TaskLib
  def initialize
    super()
    desc "Bootstrap a new database so you can use the app."
    task :bootstrap do
      Suma.load_app
      Suma::PlatformPartner.find_or_create(name: "Spin")
      require "suma/mobility_vehicle/sync_spin"
      Suma::MobilityVehicle::SyncSpin.sync_all
    end
  end
end
