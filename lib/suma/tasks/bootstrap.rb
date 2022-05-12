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
      org.db.transaction do
        ["Food", "Mobility", "Cash"].each { |n| Suma::Vendor::ServiceCategory.find_or_create(name: n) }
        rate = Suma::Vendor::ServiceRate.find_or_create(name: "Mobility $1 start $0.20/minute") do |r|
          r.localization_key = "mobility_start_and_per_minute"
          r.surcharge = Money.new(100)
          r.unit_amount = Money.new(20)
        end
        spin = Suma::Vendor.find_or_create(name: "Spin", organization: org)
        if spin.services_dataset.mobility.empty?
          svc = spin.add_service(
            internal_name: "Portland Scooters",
            external_name: "Spin E-Scooters",
            sync_url: "https://gbfs.spin.pm/api/gbfs/v2_2/portland/free_bike_status",
            mobility_vendor_adapter_key: "fake",
          )
          svc.add_category(Suma::Vendor::ServiceCategory.find_or_create(name: "Mobility"))
          svc.add_category(Suma::Vendor::ServiceCategory.find_or_create(name: "Cash"))
          svc.add_rate(rate)
        end
      end
      require "suma/mobility/sync_spin"
      i = org.db.transaction do
        Suma::Mobility::SyncSpin.sync_all
      end
      puts "Synced #{i} scooters"
    end
  end
end
