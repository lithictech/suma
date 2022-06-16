# frozen_string_literal: true

require "rake/tasklib"

require "suma/tasks"

class Suma::Tasks::Bootstrap < Rake::TaskLib
  def initialize
    super()
    desc "Bootstrap a new database so you can use the app."
    task :bootstrap do
      Suma.load_app
      usa = Suma::SupportedGeography.find_or_create(label: "USA", value: "United States of America", type: "country")
      Suma::SupportedGeography.find_or_create(
        label: "Oregon", value: "Oregon", type: "province", parent: usa,
      )
      Suma::SupportedGeography.find_or_create(
        label: "North Carolina", value: "North Carolina", type: "province", parent: usa,
      )

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
      admin = Suma::Member.find_or_create(email: "admin@lithic.tech") do |c|
        c.password = "Password1!"
        c.name = "Suma Admin"
        c.phone = "15552223333"
      end
      admin.ensure_role(Suma::Role.admin_role)
      Suma::SupportedCurrency.find_or_create(code: "USD") do |c|
        c.symbol = "$"
        c.funding_minimum_cents = 500
        c.funding_step_cents = 100
        c.cents_in_dollar = 100
        c.payment_method_types = ["bank_account"]
        c.ordinal = 1
      end
    end
  end
end
