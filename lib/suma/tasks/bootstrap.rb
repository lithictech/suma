# frozen_string_literal: true

require "rake/tasklib"

require "suma/tasks"

class Suma::Tasks::Bootstrap < Rake::TaskLib
  def initialize
    super()
    desc "Bootstrap a new database so you can use the app."
    task :bootstrap do
      Suma.load_app
      org = Suma::Organization.find_or_create(name: "Spin")
      Suma::Vendor.find_or_create(name: "Spin", organization: org)
      require "suma/mobility_vehicle/sync_spin"
      Suma::MobilityVehicle::SyncSpin.sync_all
    end
  end
end
