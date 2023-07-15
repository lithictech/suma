# frozen_string_literal: true

require "rake/tasklib"

require "suma/tasks"
require "suma/lime"

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

      self.create_lime_scooter_vendor
      self.sync_lime_gbfs

      self.setup_admin

      self.setup_noimage_offering

      self.setup_holiday_offering
      self.setup_holiday_products

      self.setup_sjfm

      self.setup_private_accounts

      self.setup_automation

      self.assign_fakeuser_constraints
    end
  end

  def cash_category
    return Suma::Vendor::ServiceCategory.find_or_create(name: "Cash")
  end

  def mobility_category
    Suma::Vendor::ServiceCategory.find_or_create(name: "Mobility", parent: cash_category)
  end

  def food_category
    Suma::Vendor::ServiceCategory.find_or_create(name: "Food", parent: cash_category)
  end

  def holidays_category
    Suma::Vendor::ServiceCategory.find_or_create(name: "Holiday 2022 Promo", parent: food_category)
  end

  def farmers_market_category
    Suma::Vendor::ServiceCategory.find_or_create(name: "Summer 2023 Farmers Market", parent: cash_category)
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
      c.funding_step_cents = 100
      c.cents_in_dollar = 100
      c.payment_method_types = ["bank_account", "card"]
      c.ordinal = 1
    end
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
      r.localization_key = "mobility_lime_access_summer_2023_rate"
      r.surcharge = Money.new(0)
      r.unit_amount = Money.new(7)
    end
    Suma::Vendor::Service.
      where(mobility_vendor_adapter_key: "lime").
      update(mobility_vendor_adapter_key: "lime_deeplink")
    svc = Suma::Vendor::Service.update_or_create(vendor:, internal_name: "Lime Scooter Deeplink") do |vs|
      vs.external_name = "Lime E-Scooter"
      vs.constraints = [{"form_factor" => "scooter", "propulsion_type" => "electric"}]
      vs.mobility_vendor_adapter_key = "lime_deeplink"
    end
    svc.add_category(Suma::Vendor::ServiceCategory.update_or_create(name: "Mobility", parent: cash_category)) if
      svc.categories.empty?
    svc.add_rate(rate) if svc.rates.empty?
  end

  ADMIN_EMAIL = "admin@lithic.tech"

  def setup_admin
    return unless Suma::RACK_ENV == "development"
    admin = Suma::Member.find_or_create(email: ADMIN_EMAIL) do |c|
      c.password = "Password1!"
      c.name = "Suma Admin"
      c.phone = "15552223333"
    end
    admin.ensure_role(Suma::Role.admin_role)
  end

  def assign_fakeuser_constraints
    Suma::Eligibility::Constraint.assign_to_admins
  end

  def setup_holiday_offering
    offering = Suma::Commerce::Offering.update_or_create(confirmation_template: "2022-12-pilot-confirmation") do |o|
      o.period = self.holiday_2022_begin..self.holiday_2022_end
      o.description = Suma::TranslatedText.find_or_create(en: "Holidays 2022", es: "Días festivos")
      o.fulfillment_prompt = Suma::TranslatedText.find_or_create(
        en: "How do you want to get your stuff?",
        es: "¿Cómo desea obtener sus cosas?",
      )
      o.fulfillment_confirmation = Suma::TranslatedText.find_or_create(
        en: "How you’re getting it",
        es: "Cómo lo está recibiendo",
      )
    end
    uf = self.create_uploaded_file("holiday-offering.jpeg", "image/jpeg")
    offering.add_image({uploaded_file: uf}) if offering.images.empty?

    return unless offering.fulfillment_options.empty?
    offering.add_fulfillment_option(
      type: "pickup",
      ordinal: 0,
      description: Suma::TranslatedText.find_or_create(
        en: "Pickup at Sheridan's Market (Dec 21-22)",
        es: "Recogida en Sheridan's Market (21-22 de dic)",
      ),
      address: Suma::Address.lookup(
        address1: "409 SE Martin Luther King Jr Blvd",
        city: "Portland",
        state_or_province: "Oregon",
        postal_code: "97214",
      ),
    )
    offering.add_fulfillment_option(
      type: "pickup",
      ordinal: 1,
      description: Suma::TranslatedText.find_or_create(
        en: "Pickup at Community Location (Dec 21-22)",
        es: "Recogida en una ubicación de la comunidad (21-22 de dic)",
      ),
    )
  end

  def setup_noimage_offering
    return unless Suma::RACK_ENV == "development"
    desc = Suma::TranslatedText.find_or_create(en: "No Image Tester", es: "No Image Tester (es)")
    Suma::Commerce::Offering.update_or_create(description: desc) do |o|
      o.period = 1.day.ago..6.months.from_now
      o.fulfillment_prompt = Suma::TranslatedText.find_or_create(en: "EN prompt", es: "ES prompt")
      o.fulfillment_confirmation = Suma::TranslatedText.find_or_create(en: "EN confirmation", es: "ES confirmation")
    end
  end

  def setup_holiday_products
    return unless Suma::Commerce::Product.dataset.empty?

    # rubocop:disable Layout/LineLength
    products = [
      {
        name_en: "Roasted Turkey Dinner, feeds 4-6",
        name_es: "Cena De Pavo Asado, Alimenta 4-6 personas",
        desc_en: "Roasted Turkey, Stuffing, Buttermilk Mashed Potatoes, Gravy, Dinner Rolls, Roasted Green Beans, Pumpkin Pie",
        desc_es: "Pavo Asado, Relleno, Puré de Papas y Su Salsa, Panecillos, Ejotes Asados, y Pastel de Calabaza",
        image: "turkey-dinner.jpeg",
      },
      {
        name_en: "Glazed Ham Dinner, feeds 4-6",
        name_es: "Cena De Jamón Glaseado, Alimenta 4-6 personas",
        desc_en: "Glazed Ham, Stuffing, Buttermilk Mashed Potatoes, Gravy, Dinner Rolls, Roasted Green Beans, Pumpkin Pie",
        desc_es: "Hamon Glaseado, Relleno, Puré de Papas y Su Salsa, Panecillos, Ejotes Asados, y Pastel de Calabaza",
        image: "ham-dinner.jpeg",
      },
      {
        name_en: "Vegan Field Roast Dinner, feeds 4-6",
        name_es: "Cena De Asado Vegano, Alimenta 4-6 personas",
        desc_en: "Vegan Field Roast, Gluten-Free Stuffing, Gluten-Free Coconut Milk Mashed Potatoes, Gravy, Gluten-Free Dinner Rolls, Roasted Green Beans, Gluten-Free Pumpkin Pie",
        desc_es: "Asado Vegano, Relleno sin Gluten, Puré de Papas de Leche de Coco (y sin gluten) y Su Salsa Vegano, Panecillos sin Gluten, Ejotes Asados, y Pastel de Calabaza Vegano",
        image: "vegan-field-roast-dinner.jpeg",
      },
    ]
    # rubocop:enable Layout/LineLength

    offering = Suma::Commerce::Offering.find!(confirmation_template: "2022-12-pilot-confirmation")
    products.each do |ps|
      product = Suma::Commerce::Product.create(
        name: Suma::TranslatedText.create(en: ps[:name_en], es: ps[:name_es]),
        description: Suma::TranslatedText.create(en: ps[:desc_en], es: ps[:desc_es]),
        vendor: Suma::Vendor.find_or_create(name: "Sheridan's Market"),
        our_cost: Money.new(90_00),
      )
      Suma::Commerce::ProductInventory.create(
        product:,
        max_quantity_per_order: 1,
        max_quantity_per_offering: 1,
      )
      product.add_vendor_service_category(holidays_category)
      uf = self.create_uploaded_file(ps[:image], "image/jpeg")
      product.add_image({uploaded_file: uf})
      Suma::Commerce::OfferingProduct.create(
        offering:,
        product:,
        customer_price: Money.new(90_00),
        undiscounted_price: Money.new(180_00),
      )
    end
  end

  def setup_sjfm
    market_name = "St. Johns Farmers Market"
    market_address = Suma::Address.lookup(
      address1: "N Charleston Ave & N Central St",
      city: "Portland",
      state_or_province: "Oregon",
      postal_code: "97203",
    )
    logo = self.create_uploaded_file("st-johns-farmers-market-logo.png", "image/png")
    hero = self.create_uploaded_file("st-johns-farmers-market-hero.jpeg", "image/jpeg")

    offering = Suma::Commerce::Offering.update_or_create(confirmation_template: "2023-07-pilot-confirmation") do |o|
      o.set(
        period: self.sjfm_2023_begin..self.sjfm_2023_end,
        description: Suma::TranslatedText.find_or_create(
          en: "#{market_name} Ride & Shop",
          es: "Paseo y Compra en #{market_name}",
        ),
        fulfillment_prompt: Suma::TranslatedText.find_or_create(
          en: "Do you need transportation?",
          es: "¿Necesitas transporte?",
        ),
        fulfillment_confirmation: Suma::TranslatedText.find_or_create(
          en: "Transportation needed",
          es: "Necesito transporte",
        ),
        begin_fulfillment_at: self.sjfm_2023_end,
      )
    end

    if offering.images.empty?
      offering.add_image({uploaded_file: hero})
    else
      offering.images.first.update(uploaded_file: hero)
    end

    if offering.eligibility_constraints.empty?
      constraint = Suma::Eligibility::Constraint.find_or_create(name: "New Columbia, Portland, OR")
      offering.add_eligibility_constraint(constraint)
    end

    fulfillment_params = [
      {
        type: "pickup",
        ordinal: 0,
        description: Suma::TranslatedText.find_or_create(
          en: "Yes, please contact me",
          es: "Sí, por favor contácteme",
        ),
        address: market_address,
      },
      {
        type: "pickup",
        ordinal: 1,
        description: Suma::TranslatedText.find_or_create(
          en: "No, I have my own transportation",
          es: "No, tengo mi propio transporte",
        ),
        address: market_address,
      },
    ]
    if offering.fulfillment_options.empty?
      fulfillment_params.each { |o| offering.add_fulfillment_option(o) }
    else
      fulfillment_params.each_with_index do |o, i|
        offering.fulfillment_options[i].update(o)
      end
    end

    product_name = Suma::TranslatedText.find_or_create(en: "$24 in #{market_name} Vouchers",
                                                       es: "$24 en Cupones de #{market_name}",)
    product = Suma::Commerce::Product.update_or_create(name: product_name) do |p|
      # rubocop:disable Layout/LineLength
      p.description = Suma::TranslatedText.find_or_create(
        en: "The suma voucher is a food special in which a suma user loads $5 and gets $24 in vouchers for fresh and packaged food at #{market_name}. You cannot use these vouchers for alcohol or hot prepared foods. This special is open to New Columbia residents only",
        es: "El cupón de suma es un especial de alimentos en el que un usuario de suma carga $5 y obtiene $24 en cupones para alimentos frescos y empaquetados en #{market_name}. No puede utilizar estos cupones para bebidas alcohólicas o comidas preparadas calientes. Este especial está abierto solo para los residentes de New Columbia.",
      )
      # rubocop:enable Layout/LineLength
      p.vendor = Suma::Vendor.update_or_create(name: market_name)
      p.our_cost = Money.new(2400)
    end
    product.add_vendor_service_category(farmers_market_category) if product.vendor_service_categories.empty?
    if product.images.empty?
      product.add_image({uploaded_file: logo})
    else
      product.images.first.update(uploaded_file: logo)
    end
    Suma::Commerce::ProductInventory.update_or_create(product:) do |p|
      p.max_quantity_per_order = 1
      p.max_quantity_per_offering = 25
    end
    Suma::Commerce::OfferingProduct.update_or_create(offering:, product:) do |op|
      op.customer_price = Money.new(2400)
      op.undiscounted_price = Money.new(2400)
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
    Suma::AnonProxy::VendorConfiguration.update_or_create(vendor: lime_vendor) do |vc|
      vc.uses_email = true
      vc.uses_sms = false
      vc.enabled = true
      vc.message_handler_key = "lime"
      vc.app_launch_link = "https://limebike.app.link/m2h6hB9qrS"
      vc.instructions = Suma::TranslatedText.find_or_create(
        en: <<~MD,
          1. Download the Lime App in the Play or App Store, or follow <a href="https://limebike.app.link/m2h6hB9qrS" target="_blank">this link</a>.
          2. Start the Lime App.
          3. When prompted to sign in, choose 'Other options'
          4. Choose 'Email'
          5. Enter the email **<Copyable>%{address}</Copyable>**, and press 'Next'.
          6. The next screen is 'Check Your Email'. Instead, **reopen the Suma web app.**
          7. Within a few seconds, a verification code will appear in Suma.
          8. Once it does, copy the code.
          9. Go back to Lime, press 'Enter Code', paste the code into the Lime app, and press 'Next'.
          10. You are logged into Lime and ready to start riding.
        MD
        es: <<~MD,
          1. Descargue la aplicación Lime en Play o App Store, o siga [este enlace](https://limebike.app.link/m2h6hB9qrS)
          2. Inicie la aplicación Lime.
          3. Cuando se le solicite iniciar sesión, elija 'Otras opciones'
          4. Elija 'Email'
          5. Ingrese el correo electrónico **%{address}**, y presione 'Siguiente'.
          6. La siguiente pantalla es 'Verifique su correo electrónico'. Sin embargo, **su código llegará a través de SMS.** Presione 'Ingresar código' para continuar.
          7. En unos segundos, Suma te enviará un SMS con el código de Lime. Copia el código.
          8. Pegue el código en la aplicación de Lime y presione 'Siguiente'.
          9. ¡Estás listo!
        MD
      )
    end
  end

  def setup_automation
    Suma::AutomationTrigger.dataset.delete
    Suma::AutomationTrigger.create(
      name: "Holidays 2022 Promo",
      topic: "suma.member.created",
      active_during_begin: self.holiday_2022_begin,
      active_during_end: self.holiday_2022_end,
      klass_name: "Suma::AutomationTrigger::CreateAndSubsidizeLedger",
      parameter: {
        ledger_name: "Holidays2022Promo",
        contribution_text: {en: "Holiday 2022 Subsidy", es: "Subsidio Vacaciones 2022"},
        category_name: "Holiday 2022 Promo",
        amount_cents: 80_00,
        amount_currency: "USD",
        subsidy_memo: {
          en: "Subsidy from local funders",
          es: "Apoyo de financiadores locales",
        },
      },
    )
    Suma::AutomationTrigger.create(
      name: "Holidays 2022 Pilot Verification",
      topic: "suma.member.created",
      active_during_begin: self.holiday_2022_begin,
      active_during_end: self.holiday_2022_end,
      klass_name: "Suma::AutomationTrigger::AutoOnboard",
    )
    Suma::AutomationTrigger.create(
      name: "Summer 2023 Promo",
      topic: "suma.member.eligibilitychanged",
      active_during_begin: self.sjfm_2023_begin,
      active_during_end: self.sjfm_2023_end,
      klass_name: "Suma::AutomationTrigger::CreateAndSubsidizeLedger",
      parameter: {
        ledger_name: "Summer2023FarmersMarket",
        contribution_text: {en: "Summer 2023 Market Subsidy", es: "Subsidio Verano Mercado 2023"},
        category_name: "Summer 2023 Farmers Market",
        amount_cents: 19_00,
        amount_currency: "USD",
        subsidy_memo: {
          en: "Farmers Market subsidy",
          es: "Subsidio al mercado de agricultores",
        },
        verified_constraint_name: "New Columbia, Portland, OR",
      },
    )
  end

  def holiday_2022_begin = Time.parse("2023-11-01T12:00:00-0700")
  def holiday_2022_end = Time.parse("2023-12-18T12:00:00-0700")

  def sjfm_2023_begin = Time.parse("2023-06-01T12:00:00-0700")
  def sjfm_2023_end = Time.parse("2023-07-15T23:00:00-0700")

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
