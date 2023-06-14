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

      Suma::Member.db.transaction do
        self.create_meta_resources

        self.sync_lime_gbfs

        self.setup_admin

        self.setup_offerings
        self.setup_products
        self.setup_automation

        self.setup_market_offering_product
      end
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

  def setup_offerings
    return unless Suma::Commerce::Offering.dataset.empty?

    offering = Suma::Commerce::Offering.new
    offering.period = 1.day.ago..self.pilot_end
    offering.description = Suma::TranslatedText.create(en: "Holidays 2022", es: "Días festivos")
    offering.confirmation_template = "2022-12-pilot-confirmation"
    offering.save_changes
    uf = self.create_uploaded_file(filename: "holiday-offering.jpeg", content_type: "image/jpeg")
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

    # Create this extra one
    Suma::RACK_ENV == "development" && Suma::Commerce::Offering.create(
      description_string: "No Image Tester",
      period: 1.day.ago..self.pilot_end,
    )
  end

  def setup_products
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
      uf = self.create_uploaded_file(filename: ps[:image], content_type: "image/jpeg")
      product.add_image({uploaded_file: uf})
      Suma::Commerce::OfferingProduct.create(
        offering:,
        product:,
        customer_price: Money.new(90_00),
        undiscounted_price: Money.new(180_00),
      )
    end
  end

  def setup_market_offering_product
    market_name = "St. Johns Farmers Market"
    offering = Suma::Commerce::Offering.find_or_create(confirmation_template: "2023-06-pilot-confirmation") do |o|
      o.period = 1.day.ago..self.pilot_end
      o.description = Suma::TranslatedText.create(en: "Suma Farmers Market Ride & Shop",
                                                  es: "Paseo y tienda en el mercado de agricultores de Suma",)
    end
    uf = self.create_uploaded_file(name: "st-johns-farmers-market.png", content_type: "image/png")
    offering.add_image({uploaded_file: uf})

    if offering.fulfillment_options.empty?
      offering.add_fulfillment_option(
        type: "pickup",
        ordinal: 0,
        description: Suma::TranslatedText.create(
          en: "Redeem this voucher at #{market_name} (July 16 2023).
               For more information check the product details.",
          es: "Reclame este boleto en #{market_name} (16 julio 2023). Para
               más información verifique los detalles del producto.",
        ),
        address: Suma::Address.lookup(
          address1: "N Charleston Avenue &, N Central Street",
          city: "Portland",
          state_or_province: "Oregon",
          postal_code: "97203",
        ),
      )
    end

    suma_org = Suma::Organization.find_or_create(name: "suma")
    product_name = Suma::TranslatedText.find_or_create(en: "$24 Token", es: "Ficha de $24")
    product = Suma::Commerce::Product.find_or_create(name: product_name) do |p|
      p.description = Suma::TranslatedText.create(
        en: "Farmer's Market voucher only valid through 2023.
             It can be used to buy anything in #{market_name}.",
        es: "El boleto del Farmer's Market solo es válido durante 2023.
             Se puede usar para comprar cualquier cosa en #{market_name}.",
      )
      p.vendor = Suma::Vendor.find_or_create(name: market_name, organization: suma_org)
      p.our_cost = Money.new(2400)
    end
    product.add_vendor_service_category(farmers_market_category) if product.vendor_service_categories.empty?
    uf = self.create_uploaded_file(filename: "suma-voucher-front.jpg", content_type: "image/jpeg")
    product.add_image({uploaded_file: uf}) if product.images.empty?
    Suma::Commerce::ProductInventory.find_or_create(product:) do |p|
      p.max_quantity_per_order = 1
      p.max_quantity_per_offering = 50
    end
    Suma::Commerce::OfferingProduct.find_or_create(offering:, product:) do |op|
      op.customer_price = Money.new(2400)
      op.undiscounted_price = Money.new(2400)
    end
  end

  def setup_automation
    Suma::AutomationTrigger.dataset.delete
    Suma::AutomationTrigger.create(
      name: "Holidays 2022 Promo",
      topic: "suma.payment.account.created",
      active_during_begin: Time.now,
      active_during_end: self.pilot_end,
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
      active_during_begin: Time.now,
      active_during_end: self.pilot_end,
      klass_name: "Suma::AutomationTrigger::AutoOnboard",
    )
  end

  def pilot_end
    return Time.now + 6.months
  end

  def self.create_uploaded_file(filename, content_type, file_path: "spec/data/images/")
    bytes = File.binread(file_path + filename)
    return Suma::UploadedFile.create_with_blob(bytes:, content_type:, filename:)
  end
end
