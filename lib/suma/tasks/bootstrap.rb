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

      self.sync_lime_gbfs

      self.setup_admin

      self.setup_noimage_offering

      self.setup_holiday_offering
      self.setup_holiday_products

      self.setup_sjfm

      self.setup_automation
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
      puts "Synced #{i} #{c.model.name}"
    end
  end

  def self.create_lime_scooter_vendor
    lime_vendor = Suma::Lime.mobility_vendor
    return unless lime_vendor.services_dataset.mobility.empty?
    rate = Suma::Vendor::ServiceRate.find_or_create(name: "Ride for free") do |r|
      r.localization_key = "mobility_free_of_charge"
      r.surcharge = Money.new(0)
      r.unit_amount = Money.new(0)
    end
    cash_category = Suma::Vendor::ServiceCategory.find_or_create(name: "Cash")
    svc = lime_vendor.add_service(
      internal_name: "Lime Scooters",
      external_name: "Lime E-Scooters",
      mobility_vendor_adapter_key: "lime",
      constraints: [{"form_factor" => "scooter", "propulsion_type" => "electric"}],
    )
    svc.add_category(Suma::Vendor::ServiceCategory.find_or_create(name: "Mobility", parent: cash_category))
    svc.add_rate(rate)
  end

  def setup_admin
    admin = Suma::Member.find_or_create(email: "admin@lithic.tech") do |c|
      c.password = "Password1!"
      c.name = "Suma Admin"
      c.phone = "15552223333"
    end
    admin.ensure_role(Suma::Role.admin_role)
  end

  def setup_holiday_offering
    return unless Suma::Commerce::Offering.dataset.empty?

    offering = Suma::Commerce::Offering.new
    offering.period = 1.day.ago..self.holiday_2022_end
    offering.description = Suma::TranslatedText.create(en: "Holidays 2022", es: "Días festivos")
    offering.confirmation_template = "2022-12-pilot-confirmation"
    offering.save_changes
    uf = self.create_uploaded_file("holiday-offering.jpeg", "image/jpeg")
    offering.add_image({uploaded_file: uf})

    offering.add_fulfillment_option(
      type: "pickup",
      ordinal: 0,
      description: Suma::TranslatedText.create(
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
      description: Suma::TranslatedText.create(
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

    suma_org = Suma::Organization.find_or_create(name: "suma")
    offering = Suma::Commerce::Offering.first
    products.each do |ps|
      product = Suma::Commerce::Product.create(
        name: Suma::TranslatedText.create(en: ps[:name_en], es: ps[:name_es]),
        description: Suma::TranslatedText.create(en: ps[:desc_en], es: ps[:desc_es]),
        vendor: Suma::Vendor.find_or_create(name: "Sheridan's Market", organization: suma_org),
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
          es: "Do you need transportation? TODO",
        ),
        fulfillment_confirmation: Suma::TranslatedText.find_or_create(
          en: "Transportation needed",
          es: "Transportation needed TODO",
        ),
        begin_fulfillment_at: self.sjfm_2023_end,
      )
    end
    if offering.images.empty?
      offering.add_image({uploaded_file: hero})
    else
      offering.images.first.update(uploaded_file: hero)
    end

    fulfillment_params = [
      {
        type: "pickup",
        ordinal: 0,
        description: Suma::TranslatedText.find_or_create(
          en: "Yes, please contact me",
          es: "TODO",
        ),
        address: market_address,
      },
      {
        type: "pickup",
        ordinal: 1,
        description: Suma::TranslatedText.find_or_create(
          en: "No, I have my own transportation",
          es: "TODO",
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

    suma_org = Suma::Organization.find_or_create(name: "suma")
    product_name = Suma::TranslatedText.find_or_create(en: "$24 in #{market_name} Vouchers",
                                                       es: "$24 en Cupones de #{market_name}",)
    product = Suma::Commerce::Product.update_or_create(name: product_name) do |p|
      # rubocop:disable Layout/LineLength
      p.description = Suma::TranslatedText.find_or_create(
        en: "The suma voucher is a food special in which a suma user loads $5 and gets $24 in vouchers for fresh and packaged food at #{market_name}. You cannot use these vouchers for alcohol or hot prepared foods.",
        es: "El cupón de suma es un especial de alimentos en el que un usuario de suma carga $5 y obtiene $24 en cupones para alimentos frescos y empaquetados en #{market_name}. No puede utilizar estos cupones para bebidas alcohólicas o comidas preparadas calientes.",
      )
      # rubocop:enable Layout/LineLength
      p.vendor = Suma::Vendor.update_or_create(name: market_name, organization: suma_org)
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

  def setup_automation
    Suma::AutomationTrigger.dataset.delete
    Suma::AutomationTrigger.create(
      name: "Holidays 2022 Promo",
      topic: "suma.payment.account.created",
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
      topic: "suma.payment.account.created",
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
          en: "Subsidy from local funders",
          es: "Apoyo de financiadores locales",
        },
      },
    )
  end

  def holiday_2022_begin = Time.parse("2023-11-01T12:00:00-0700")
  def holiday_2022_end = Time.parse("2023-12-18T12:00:00-0700")

  def sjfm_2023_begin = Time.parse("2023-06-01T12:00:00-0700")
  def sjfm_2023_end = Time.parse("2023-07-15T12:00:00-0700")

  def create_uploaded_file(filename, content_type, file_path: "spec/data/images/")
    bytes = File.binread(file_path + filename)
    return Suma::UploadedFile.create_with_blob(bytes:, content_type:, filename:)
  end
end
