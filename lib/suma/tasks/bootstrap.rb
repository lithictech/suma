# frozen_string_literal: true

require "rake/tasklib"

require "suma/tasks"

# rubocop:disable Layout/LineLength
class Suma::Tasks::Bootstrap < Rake::TaskLib
  def initialize
    super
    desc "Bootstrap a new database so you can use the app."
    task :bootstrap do
      raise "only run this in development" unless Suma::RACK_ENV == "development"
      ENV["SUMA_DB_SLOW_QUERY_SECONDS"] = "1"
      Suma.load_app
      raise "only run with a fresh database" unless Suma::Member.dataset.empty?
      SequelTranslatedText.language = :en
      self.run_task
    end
  end

  def run_task
    Suma::Member.db.transaction do
      Meta.new.fixture
      Mobility.new.fixture
      AnonProxy.new.fixture
      Commerce.new.fixture
      Programs.new.fixture
    end
  end

  class Common
    def cash_category = Suma::Vendor::ServiceCategory.find_or_create(name: "Cash")
    def mobility_category = Suma::Vendor::ServiceCategory.find_or_create(name: "Mobility", parent: cash_category)
    def food_category = Suma::Vendor::ServiceCategory.find_or_create(name: "Food", parent: cash_category)
    def holidays_category = Suma::Vendor::ServiceCategory.find_or_create(name: "Holiday Demo", parent: food_category)
    def farmers_market_intro_category = Suma::Vendor::ServiceCategory.find_or_create(name: "Farmers Market Demo", parent: cash_category)
    def farmers_market_match_category = Suma::Vendor::ServiceCategory.find_or_create(name: "Farmers Market Match Demo", parent: cash_category)

    def create_uploaded_file(filename, content_type, file_path: "spec/data/images/")
      bytes = File.binread(file_path + filename)
      return Suma::UploadedFile.create_with_blob(bytes:, content_type:, filename:)
    end
  end

  class Meta < Common
    ADMIN_EMAIL = "admin@lithic.tech"
    ADMIN_PHONE = "15552223333"
    ADMIN_PASS = "Password1!"

    def fixture
      Suma::Payment.ensure_cash_ledger(Suma::Payment::Account.lookup_platform_account)

      admin = Suma::Member.create(email: ADMIN_EMAIL) do |c|
        c.name = "Suma Admin"
        c.password = ADMIN_PASS
        c.phone = ADMIN_PHONE
        c.onboarding_verified_at = Time.now
      end
      admin.ensure_role(Suma::Role.cache.admin)
      Suma::Payment.ensure_cash_ledger(admin)

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

      Suma::Organization.find_or_create(name: "Affordable Housing")
      Suma::Organization.find_or_create(name: "Homes for All")
    end
  end

  class Mobility < Common
    def fixture
      lime_vs = self.create_mobility_vendor_service(
        vendor_name: "Lime",
        rate_name: "Demo Scooter Rate",
        internal_name: "lime_demo_mobility_deeplink",
        external_name: "Lime Demo E-Scooter",
        constraints: [{"form_factor" => "scooter", "propulsion_type" => "electric"}],
        rate_surcharge: Money.new(0),
        rate_unit_amount: Money.new(7),
        mobility_vendor_adapter_key: "lime_deeplink",
      )
      # Lime: "https://data.lime.bike/api/partners/v2/gbfs_transit"
      lyft_vs = self.create_mobility_vendor_service(
        vendor_name: "Lyft",
        internal_name: "biketown_demo_mobility_deeplink",
        external_name: "Biketown Demo E-Bike",
        constraints: [{"form_factor" => "bicycle", "propulsion_type" => "electric_assist"}],
        rate_name: "Demo Bike Rate",
        rate_surcharge: Money.new(0),
        rate_unit_amount: Money.new(10),
        mobility_vendor_adapter_key: "lyft_deeplink",
      )
      Suma::Mobility::GbfsFeed.create(
        feed_root_url: "https://gbfs.lyft.com/gbfs/2.3/pdx/en",
        vendor: lyft_vs.vendor,
      )
      self.sync_bikes(vendor_service: lime_vs, vehicle_type: "escooter")
      self.sync_bikes(vendor_service: lyft_vs, vehicle_type: "ebike")
    end

    protected def create_mobility_vendor_service(
      vendor_name:,
      internal_name:,
      external_name:,
      constraints:,
      rate_name:,
      rate_surcharge:,
      rate_unit_amount:,
      mobility_vendor_adapter_key:
    )
      vendor = Suma::Vendor.create(name: vendor_name)
      rate = Suma::Vendor::ServiceRate.create(
        name: rate_name,
        localization_key: "mobility_start_and_per_minute",
        surcharge: rate_surcharge,
        unit_amount: rate_unit_amount,
      )
      svc = Suma::Vendor::Service.create(
        vendor:,
        internal_name:,
        external_name:,
        constraints:,
        mobility_vendor_adapter_key:,
        period: Time.now..1.year.from_now,
      )
      svc.add_category(Suma::Vendor::ServiceCategory.find_or_create(name: "Mobility", parent: cash_category))
      svc.add_rate(rate)
      return svc
    end

    protected def sync_bikes(vendor_service:, vehicle_type:)
      my_ip = Suma::Http.get("http://whatismyip.akamai.com", logger: nil).body
      my_geo = Suma::Http.get("http://ip-api.com/json/#{my_ip}", logger: nil)
      require "suma/fixtures/mobility_vehicles"
      Suma::Fixtures.mobility_vehicle(
        lat: my_geo.parsed_response.fetch("lat"),
        lng: my_geo.parsed_response.fetch("lon"),
        vehicle_type:,
        vendor_service:,
      ).create
    end
  end

  class AnonProxy < Common
    def fixture
      self.setup_private_accounts
    end

    protected def setup_private_accounts
      [Suma::Vendor[name: "Lime"], Suma::Vendor[name: "Lyft"]].each do |vendor|
        Suma::AnonProxy::VendorConfiguration.find_or_create(vendor:) do |vc|
          vc.enabled = true
          vc.auth_to_vendor_key = "fake"
          vc.message_handler_key = "fake"
          vc.app_install_link = "https://mysuma.org"
          vc.instructions = Suma::TranslatedText.find_or_create(
            en: <<~MD,
              1. Step 1 en
              1. Step 2 en
              1. Step 3 en
              1. Step 4 en
            MD
            es: <<~MD,
              1. Step 1 es
              1. Step 2 es
              1. Step 3 es
              1. Step 4 es
            MD
          )
        end
      end
    end
  end

  class Commerce < Common
    def fixture
      self.setup_holiday_offering
      self.setup_holiday_triggers
      self.setup_farmers_market_offering
      self.setup_farmers_market_triggers
    end

    protected def setup_holiday_offering
      offering = Suma::Commerce::Offering.create do |o|
        o.confirmation_template = "2022-12-pilot-confirmation"
        o.period = Time.now..1.year.from_now
        o.description = Suma::TranslatedText.find_or_create(en: "Holidays Demo", es: "Días festivos")
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
      offering.add_fulfillment_option(
        type: "pickup",
        ordinal: 0,
        description: Suma::TranslatedText.find_or_create(
          en: "Pickup at Market (Dec 21-22)",
          es: "Recogida en Market (21-22 de dic)",
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

      vendor = Suma::Vendor.find_or_create(name: "Local Market")
      products.each do |ps|
        self.create_product(
          name_en: ps[:name_en],
          name_es: ps[:name_es],
          description_en: ps[:desc_en],
          description_es: ps[:desc_es],
          vendor:,
          vendor_service_categories: [self.holidays_category],
          our_cost: Money.new(90_00),
          image: self.create_uploaded_file(ps[:image], "image/jpeg"),
          max_quantity_per_member_per_offering: 1,
          offering:,
          customer_price: Money.new(90_00),
          undiscounted_price: Money.new(180_00),
        )
      end
    end

    protected def setup_holiday_triggers
      Suma::Payment::Trigger.create(
        label: "Holiday food promo",
        active_during: Time.now..1.year.from_now,
        match_multiplier: 8,
        maximum_cumulative_subsidy_cents: 80_00,
        memo: Suma::TranslatedText.find_or_create(en: "Subsidy from local funders", es: "Apoyo de financiadores locales"),
        originating_ledger: Suma::Payment::Account.lookup_platform_vendor_service_category_ledger(self.holidays_category),
        receiving_ledger_name: "Holidays Food Demo",
        receiving_ledger_contribution_text: Suma::TranslatedText.find_or_create(en: "Holiday Food Subsidy", es: "Holiday Food Subsidy (es)"),
      )
    end

    def setup_farmers_market_offering
      market_name = "Demo Farmers Market"
      market_address = Suma::Address.lookup(
        address1: "NE Wygant St &, NE 7th Ave",
        city: "Portland",
        state_or_province: "Oregon",
        postal_code: "97211",
      )
      offering_period = Sequel.pg_range(Time.now..1.year.from_now)
      hero = self.create_uploaded_file("king-farmers-market-hero.jpeg", "image/jpeg")
      first_time_buyers_logo = self.create_uploaded_file("farmers-market-first-time-buyers-logo.png", "image/png")
      returning_buyers_logo = self.create_uploaded_file("farmers-market-returning-buyers-logo.png", "image/png")

      offering = Suma::Commerce::Offering.create do |o|
        o.period = offering_period
        o.confirmation_template = "2023-07-pilot-confirmation"
        o.set(
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
          begin_fulfillment_at: offering_period.begin,
        )
      end

      offering.add_image({uploaded_file: hero})
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
      fulfillment_params.each { |o| offering.add_fulfillment_option(o) }

      vendor = Suma::Vendor.update_or_create(name: market_name)
      create_product(
        name_en: "$24 in #{market_name} Vouchers",
        name_es: "$24 en Cupones de #{market_name}",
        vendor:,
        description_en: "The suma voucher is a food special where suma works with you to buy down the price of vouchers for fresh and packaged food at #{market_name}. First-time buyers load $5 and get $24 in vouchers (a $19 match from suma). You cannot use these vouchers for alcohol or hot prepared foods.",
        description_es: "El cupón de suma es un especial de alimentos en el que suma trabaja con usted para reducir el precio de los cupones para alimentos frescos y envasados en #{market_name}. Los primeros compradores cargan $5 y obtienen $24 en vales (un credito de $19 de suma). No puede utilizar estos cupones para bebidas alcohólicas o comidas preparadas calientes.",
        our_cost: Money.new(2400),
        vendor_service_categories: [farmers_market_intro_category],
        image: first_time_buyers_logo,
        max_quantity_per_member_per_offering: 1,
        customer_price: Money.new(2400),
        undiscounted_price: Money.new(2400),
        offering:,
      )
      create_product(
        vendor:,
        name_en: "#{market_name} 1 to 1 Voucher Match",
        name_es: "#{market_name} 1 a 1 de Cupones Igualados",
        description_en: "The suma voucher is a food special where suma works with you to buy down the price of vouchers for fresh and packaged food at #{market_name}. suma will match you 1:1 up to a $30 total (you load $15, suma matches with $15). You cannot use these vouchers for alcohol or hot prepared foods.",
        description_es: "El cupón de suma es un especial de alimentos en el que suma trabaja con usted para reducir el precio de los cupones para alimentos frescos y envasados en #{market_name}. suma te igualara 1:1 hasta un total de $30 (tu agregas $15, suma agrega $15 de créditos). No puede utilizar estos cupones para bebidas alcohólicas o comidas preparadas calientes.",
        our_cost: Money.new(200),
        vendor_service_categories: [farmers_market_match_category],
        image: returning_buyers_logo,
        max_quantity_per_member_per_offering: 500,
        customer_price: Money.new(200),
        undiscounted_price: Money.new(200),
        offering:,
      )
    end

    def create_product(
      name_en:,
      name_es:,
      description_en:,
      description_es:,
      vendor:,
      our_cost:,
      vendor_service_categories:,
      image:,
      max_quantity_per_member_per_offering:,
      offering:,
      customer_price:,
      undiscounted_price:
    )
      product_name = Suma::TranslatedText.create(en: name_en, es: name_es)
      product = Suma::Commerce::Product.create(name: product_name) do |p|
        p.description = Suma::TranslatedText.create(en: description_en, es: description_es)
        p.vendor = vendor
        p.our_cost = our_cost
      end
      vendor_service_categories.each { |vsc| product.add_vendor_service_category(vsc) }
      product.add_image({uploaded_file: image})
      Suma::Commerce::ProductInventory.create(product:) do |p|
        p.max_quantity_per_member_per_offering = max_quantity_per_member_per_offering
      end
      Suma::Commerce::OfferingProduct.create(offering:, product:) do |op|
        op.customer_price = customer_price
        op.undiscounted_price = undiscounted_price
      end
    end

    protected def setup_farmers_market_triggers
      Suma::Payment::Trigger.create(
        label: "Farmers market 5 for 19 signup",
        active_during: Time.now..1.year.from_now,
        match_multiplier: 3.8,
        maximum_cumulative_subsidy_cents: 1900,
        memo: Suma::TranslatedText.find_or_create(en: "Subsidy from local funders", es: "Apoyo de financiadores locales"),
        originating_ledger: Suma::Payment::Account.lookup_platform_vendor_service_category_ledger(self.farmers_market_intro_category),
        receiving_ledger_name: "Farmers Market Intro Demo",
        receiving_ledger_contribution_text: Suma::TranslatedText.find_or_create(en: "FM Intro Offer", es: "FM Intro Offer (es)"),
      )
      Suma::Payment::Trigger.create(
        label: "Farmers market 1 to 1",
        active_during: Time.now..1.year.from_now,
        match_multiplier: 1,
        maximum_cumulative_subsidy_cents: 1500,
        memo: Suma::TranslatedText.find_or_create(en: "Subsidy from local funders", es: "Apoyo de financiadores locales"),
        originating_ledger: Suma::Payment::Account.lookup_platform_vendor_service_category_ledger(self.farmers_market_match_category),
        receiving_ledger_name: "Farmers Market Match Demo",
        receiving_ledger_contribution_text: Suma::TranslatedText.find_or_create(en: "FM Match", es: "FM Match (es)"),
      )
    end
  end

  class Programs
    def fixture
      mobility_program_name = Suma::TranslatedText.find_or_create(en: "Micromobility", es: "Micromobility (ES)")
      mobility_program = Suma::Program.find_or_create(name: mobility_program_name) do |g|
        g.description = Suma::TranslatedText.find_or_create(en: "Ride electric bikes and scooters", es: "Ride electric bikes and scooters (ES)")
        g.period = 1.year.ago..1.year.from_now
        g.app_link = "/mobility"
        g.app_link_text = Suma::TranslatedText.find_or_create(en: "Check out mobility map", es: "Check out mobility map (ES)")
      end
      mobility_program.add_enrollment(role: Suma::Role.cache.admin, approved_at: Time.now) unless
        mobility_program.enrollments.any? { |e| e.role === Suma::Role.cache.admin }

      # Matches the vendor services fixtured previously
      ["lime_demo_mobility_deeplink", "biketown_demo_mobility_deeplink"].each do |internal_name|
        vs = Suma::Vendor::Service[internal_name:]
        mobility_program.add_vendor_service(vs) unless mobility_program.vendor_services.any? { |v| v === vs }
      end

      fm_name = Suma::TranslatedText.find_or_create(en: "Farmers Markets", es: "Farmers Markets (ES)")
      fm_program = Suma::Program.find_or_create(name: fm_name) do |g|
        g.description = Suma::TranslatedText.find_or_create(en: "Get subsidized local food", es: "Get subsidized local food (ES)")
        g.period = 1.year.ago..1.year.from_now
        g.app_link = "/food"
        g.app_link_text = Suma::TranslatedText.find_or_create(en: "See offering", es: "See offering (ES)")
      end
      return unless fm_program.commerce_offerings.empty?
      fm_program.add_commerce_offering(Suma::Commerce::Offering[confirmation_template: "2022-12-pilot-confirmation"])
      fm_program.add_commerce_offering(Suma::Commerce::Offering[confirmation_template: "2023-07-pilot-confirmation"])
    end
  end
end
# rubocop:enable Layout/LineLength
