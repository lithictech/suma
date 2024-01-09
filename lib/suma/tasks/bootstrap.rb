# frozen_string_literal: true

require "rake/tasklib"

require "suma/tasks"
require "suma/lime"
require "suma/mobility/good_travel_software"

# rubocop:disable Layout/LineLength
class Suma::Tasks::Bootstrap < Rake::TaskLib
  def initialize
    super()
    desc "Bootstrap a new database so you can use the app."
    task :bootstrap do
      ENV["SUMA_DB_SLOW_QUERY_SECONDS"] = "1"
      Suma.load_app
      SequelTranslatedText.language = :en
      self.run_task
    end
  end

  def run_task
    Suma::Member.db.transaction do
      self.create_meta_resources
      self.setup_constraints
      self.create_lime_scooter_vendor
      self.sync_lime_gbfs
      self.sync_gts_gbfs
      self.setup_admin
      self.setup_private_accounts
      self.assign_fakeuser_constraints
    end
  end

  def cash_category
    return Suma::Vendor::ServiceCategory.find_or_create(name: "Cash")
  end

  def mobility_category
    Suma::Vendor::ServiceCategory.find_or_create(name: "Mobility", parent: cash_category)
  end

  def create_meta_resources
    usa = Suma::SupportedGeography.find_or_create(label: "USA", value: "United States of America", type: "country")
    Suma::SupportedGeography.find_or_create(
      label: "Oregon", value: "Oregon", type: "province", parent: usa,
    )
    Suma::SupportedGeography.find_or_create(
      label: "North Carolina", value: "North Carolina", type: "province", parent: usa,
    )

    Suma::SupportedCurrency.find_or_create(code: "USD") do |c|
      c.symbol = "$"
      c.funding_minimum_cents = 500
      c.funding_maximum_cents = 100_00
      c.funding_step_cents = 100
      c.cents_in_dollar = 100
      c.payment_method_types = ["bank_account", "card"]
      c.ordinal = 1
    end
  end

  # Add to these for when GTS fails to sync
  FAKE_GTS_CAR_COORDS = [
    [45.514495, -122.601940],
  ].freeze

  def sync_gts_gbfs
    require "suma/fixtures/mobility_vehicles"
    count = 0
    Suma::Mobility::GoodTravelSoftware.access_details.each do |ad|
      vendor = ad.mobility_vendor
      rate = Suma::Vendor::ServiceRate.update_or_create(name: "Miocar Hourly") do |r|
        r.localization_key = "miocar_hourly"
        r.surcharge = Money.new(0)
        r.unit_amount = Money.new(40_00)
      end
      svc = Suma::Vendor::Service.update_or_create(vendor:, internal_name: "Miocar Deeplink") do |vs|
        vs.external_name = "Electric Car"
        vs.constraints = [{"form_factor" => "car", "propulsion_type" => "electric"}]
        vs.mobility_vendor_adapter_key = "miocar_deeplink"
      end
      svc.add_category(Suma::Vendor::ServiceCategory.update_or_create(name: "Mobility", parent: cash_category)) if
        svc.categories.empty?
      svc.add_rate(rate) if svc.rates.empty?
      accumulate = Suma::Mobility::Gbfs::VendorSync.new(
        client: ad.gbfs_client,
        vendor:,
        component: Suma::Mobility::Gbfs::FreeBikeStatus.new,
      ).sync_all
      if accumulate.zero?
        vendor.services_dataset.mobility.each_with_index do |vendor_service, vsidx|
          FAKE_GTS_CAR_COORDS.each do |(lat, lng)|
            Suma::Fixtures.mobility_vehicle(
              lat: lat + (0.0002 * vsidx),
              lng:,
              vehicle_type: "ecar",
              vendor_service:,
            ).create
          end
        end
        puts "Create fake GTS cars"
      end
      count += accumulate
    end
    puts "Synced #{count} GTS vehicles"
  end

  # Add to these for when Lime fails to sync
  FAKE_LIME_BIKE_COORDS = [
    [45.514490, -122.601940],
  ].freeze

  def sync_lime_gbfs
    require "suma/lime"
    return unless Suma::Lime.configured?
    [Suma::Mobility::Gbfs::FreeBikeStatus, Suma::Mobility::Gbfs::GeofencingZone].each do |cc|
      c = cc.new
      i = Suma::Mobility::Gbfs::VendorSync.new(
        client: Suma::Lime.gbfs_http_client,
        vendor: Suma::Lime.mobility_vendor,
        component: c,
      ).sync_all
      if i.zero? && cc == Suma::Mobility::Gbfs::FreeBikeStatus
        require "suma/fixtures/mobility_vehicles"
        Suma::Lime.mobility_vendor.services_dataset.mobility.each_with_index do |vendor_service, vsidx|
          FAKE_LIME_BIKE_COORDS.each do |(lat, lng)|
            Suma::Fixtures.mobility_vehicle(
              lat: lat + (0.0002 * vsidx),
              lng:,
              vehicle_type: "escooter",
              vendor_service:,
            ).create
          end
        end
        puts "Create fake Lime scooters since GBFS returned no vehicles"
        i = FAKE_LIME_BIKE_COORDS.length
      end
      puts "Synced #{i} #{c.model.name}"
    end
  end

  def create_lime_scooter_vendor
    vendor = Suma::Lime.mobility_vendor
    rate = Suma::Vendor::ServiceRate.update_or_create(name: "Lime Access Summer 2023") do |r|
      r.localization_key = "mobility_start_and_per_minute"
      r.surcharge = Money.new(50)
      r.unit_amount = Money.new(7)
    end
    Suma::Vendor::Service.
      where(mobility_vendor_adapter_key: "lime").
      update(mobility_vendor_adapter_key: "native_app_deeplink")
    Suma::Vendor::Service.
      where(mobility_vendor_adapter_key: "lime_deeplink").
      update(mobility_vendor_adapter_key: "native_app_deeplink")
    svc = Suma::Vendor::Service.update_or_create(vendor:, internal_name: "Lime Scooter Deeplink") do |vs|
      vs.external_name = "Lime E-Scooter"
      vs.constraints = [{"form_factor" => "scooter", "propulsion_type" => "electric"}]
      vs.mobility_vendor_adapter_key = "native_app_deeplink"
    end
    svc.add_category(Suma::Vendor::ServiceCategory.update_or_create(name: "Mobility", parent: cash_category)) if
      svc.categories.empty?
    svc.add_rate(rate) if svc.rates.empty?
    self.assign_constraints(svc, [self.new_columbia_constraint_name, self.hacienda_cdc_constraint_name, self.snap_eligible_constraint_name])
  end

  ADMIN_EMAIL = "admin@lithic.tech"

  def setup_admin
    return unless Suma::RACK_ENV == "development"
    admin = Suma::Member.update_or_create(email: ADMIN_EMAIL) do |c|
      c.password = "Password1!"
      c.name = "Suma Admin"
      c.phone = "15552223333"
    end
    admin.ensure_role(Suma::Role.admin_role)
  end

  def assign_fakeuser_constraints
    Suma::Eligibility::Constraint.assign_to_admins
  end

  def setup_constraints
    names = [self.new_columbia_constraint_name, self.hacienda_cdc_constraint_name, self.snap_eligible_constraint_name]
    names.each do |name|
      Suma::Eligibility::Constraint.find_or_create(name:)
    end
  end

  def assign_constraints(obj, constraint_names)
    existing_names = Set.new(obj.eligibility_constraints.map(&:name))
    constraint_names.each do |name|
      next if existing_names.include?(name)
      constraint = Suma::Eligibility::Constraint.find(name:)
      obj.add_eligibility_constraint(constraint)
    end
  end

  def setup_private_accounts
    lime_vendor = Suma::Lime.mobility_vendor
    if lime_vendor.images.empty?
      uf = self.download_to_uploaded_file(
        "lime-logo.png",
        "image/png",
        "https://upload.wikimedia.org/wikipedia/commons/thumb/e/e1/Lime_%28transportation_company%29_logo.svg/520px-Lime_%28transportation_company%29_logo.svg.png",
      )
      lime_vendor.add_image({uploaded_file: uf})
    end
    anon_vendor_cfg = Suma::AnonProxy::VendorConfiguration.update_or_create(vendor: lime_vendor) do |vc|
      vc.uses_email = true
      vc.uses_sms = false
      vc.enabled = true
      vc.message_handler_key = "lime"
      vc.app_install_link = "https://limebike.app.link/m2h6hB9qrS"
      vc.auth_url = "https://web-production.lime.bike/api/rider/v2/onboarding/magic-link"
      vc.auth_body_template = "email=%{email}&user_agreement_version=5&user_agreement_country_code=US"
      vc.auth_headers = {
        "Content-Type" => "application/x-www-form-urlencoded",
        "Platform" => "Android",
        "App-Version" => "3.126.0",
        "User-Agent" => "Android Lime/3.126.0; (com.limebike; build:3.126.0; Android 33) 4.10.0",
        "X-Suma" => "holá",
      }
      vc.instructions = Suma::TranslatedText.find_or_create(
        en: <<~MD,
          1. Download the Lime App in the Play or App Store, or follow <a href="https://limebike.app.link/m2h6hB9qrS" target="_blank">this link</a>.
          2. If you already have the Lime app and are signed in, please sign out out Lime first.
          3. Press the 'Launch app' button.
          4. The suma app will take 10-60 seconds to create or sign into your Lime account.
          5. The Lime app will launch automatically.
          6. You can see available scooters in suma or in Lime, but you'll use the Lime app to take your rides.
        MD
        es: <<~MD,
          1. Descargue la aplicación Lime en Play o App Store, o siga <a href="https://limebike.app.link/m2h6hB9qrS" target="_blank">este enlace</a>.
          2. Si ya tiene la aplicación Lime y ha iniciado sesión, primero cierre sesión en Lime.
          3. Presione el botón 'Iniciar aplicación'.
          4. La aplicación suma tardará entre 10 y 60 segundos en crear o iniciar sesión en su cuenta de Lime.
          5. La aplicación Lime se iniciará automáticamente.
          6. Puedes ver los scooters disponibles en suma o en Lime, pero usarás la aplicación Lime para realizar tus viajes.
        MD
      )
    end
    self.assign_constraints(anon_vendor_cfg, [self.new_columbia_constraint_name, self.hacienda_cdc_constraint_name, self.snap_eligible_constraint_name])
  end

  def new_columbia_constraint_name = "New Columbia, Portland, OR"
  def hacienda_cdc_constraint_name = "Hacienda CDC, Portland, OR"
  def snap_eligible_constraint_name = "SNAP Eligible"

  def create_uploaded_file(filename, content_type, file_path: "spec/data/images/")
    bytes = File.binread(file_path + filename)
    return Suma::UploadedFile.create_with_blob(bytes:, content_type:, filename:)
  end

  def download_to_uploaded_file(filename, content_type, url)
    if Suma::RACK_ENV == "test"
      # Don't bother using webmock for this
      return create_uploaded_file("photo.png", "png")
    end
    bytes = Net::HTTP.get(URI.parse(url))
    return Suma::UploadedFile.create_with_blob(bytes:, content_type:, filename:)
  end
end
# rubocop:enable Layout/LineLength
