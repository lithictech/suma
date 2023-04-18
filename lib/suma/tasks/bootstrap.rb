# frozen_string_literal: true

require "rake/tasklib"

require "suma/tasks"

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

        scooterorg = self.setup_scooter_vendor
        self.sync_scooters(scooterorg)
        self.create_restricted_areas

        self.setup_admin

        self.setup_offerings
        self.setup_products
        self.setup_automation
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

  def setup_scooter_vendor
    org = Suma::Organization.find_or_create(name: "Spin")
    undiscounted_rate = Suma::Vendor::ServiceRate.find_or_create(name: "Mobility $1 start $0.30/minute") do |r|
      r.localization_key = "mobility_start_and_per_minute"
      r.surcharge = Money.new(100)
      r.unit_amount = Money.new(30)
    end
    rate = Suma::Vendor::ServiceRate.find_or_create(name: "Mobility $0.50 start $0.10/minute") do |r|
      r.localization_key = "mobility_start_and_per_minute"
      r.surcharge = Money.new(50)
      r.unit_amount = Money.new(10)
      r.undiscounted_rate = undiscounted_rate
    end
    spin = Suma::Vendor.find_or_create(slug: "spin", organization: org) do |v|
      v.name = "Demo"
    end
    if spin.services_dataset.mobility.empty?
      svc = spin.add_service(
        internal_name: "Spin Scooters",
        external_name: "Demo E-Scooters",
        sync_url: "https://gbfs.spin.pm/api/gbfs/v2_2/portland/free_bike_status",
        mobility_vendor_adapter_key: "fake",
      )
      svc.add_category(mobility_category)
      svc.add_rate(rate)
    end
    return org
  end

  def sync_scooters(org)
    require "suma/mobility/sync_spin"
    i = org.db.transaction do
      Suma::Mobility::SyncSpin.sync_all
    end
    puts "Synced #{i} scooters"
  end

  def create_restricted_areas
    Suma::Mobility::RestrictedArea.find_or_create(restriction: "do-not-park-or-ride") do |ra|
      ra.polygon = [
        [45.49584550855579, -122.68355369567871],
        [45.49576278304519, -122.68331229686737],
        [45.496168888931074, -122.68292605876921],
        [45.49607488319949, -122.68264710903166],
        [45.49703749446685, -122.68198192119598],
        [45.49724806348807, -122.68259346485138],
        [45.49600719897556, -122.68352150917053],
        [45.495977117072165, -122.6834625005722],
        [45.49584550855579, -122.68355369567871],
      ]
    end
    Suma::Mobility::RestrictedArea.find_or_create(restriction: "do-not-ride") do |ra|
      ra.polygon = [
        [45.50015270758223, -122.68442273139952],
        [45.49948719071191, -122.68540441989899],
        [45.49901906820077, -122.68492430448532],
        [45.500212866911646, -122.68348127603531],
        [45.50048734303642, -122.68365025520323],
        [45.500530582303945, -122.68397212028502],
        [45.50015270758223, -122.68442273139952],
      ]
    end
    do_not_park = [
      [
        [45.497545, -122.685026],
        [45.4971314, -122.68488],
        [45.497045, -122.6847],
        [45.496717, -122.684948],
        [45.49598, -122.68461],
        [45.495777, -122.684347],
        [45.495785, -122.684004],
        [45.4959169, -122.683655],
        [45.495728, -122.683194],
        [45.4960335, -122.682896],
        [45.4959827, -122.68276],
        [45.4956349, -122.682848],
        [45.4956349, -122.682496],
        [45.496185, -122.68174],
        [45.4965937, -122.68137],
        [45.497022, -122.681212],
        [45.4971051, -122.681268],
        [45.497308, -122.681343],
        [45.497797, -122.682384],
        [45.49768, -122.68306],
        [45.4979512, -122.683435],
        [45.4978, -122.683945],
        [45.497481, -122.684344],
        [45.49751, -122.6846],
        [45.4976071, -122.68474],
        [45.497545, -122.685026],
      ],
      [
        [45.50206179495491, -122.68491994589567],
        [45.50153071609439, -122.68461316823958],
        [45.501344602317154, -122.68466949462892],
        [45.50120172667681, -122.68466010689735],
        [45.500931013942854, -122.68455684185028],
        [45.500531522287645, -122.68468961119653],
        [45.50026456628402, -122.68468961119653],
        [45.50019312713877, -122.68461316823958],
        [45.500535282222344, -122.68412500619888],
        [45.50083513620411, -122.68403112888336],
        [45.50136340171654, -122.68418535590172],
        [45.501996937805096, -122.68425107002257],
        [45.50212665203002, -122.68437042832375],
        [45.50216613021309, -122.6845595240593],
        [45.50206179495491, -122.68491994589567],
      ],
    ]
    do_not_park.each_with_index do |coords, i|
      Suma::Mobility::RestrictedArea.find_or_create(restriction: "do-not-park-#{i}") do |ra|
        ra.polygon = coords
      end
    end
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

    bytes = File.binread("spec/data/images/holiday-offering.jpeg")
    uf = Suma::UploadedFile.create_with_blob(bytes:, content_type: "image/jpeg", filename: "holiday-offering.jpeg")
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
      bytes = File.binread("spec/data/images/#{ps[:image]}")
      uf = Suma::UploadedFile.create_with_blob(bytes:, content_type: "image/jpeg", filename: ps[:image])
      product.add_image({uploaded_file: uf})
      Suma::Commerce::OfferingProduct.create(
        offering:,
        product:,
        customer_price: Money.new(90_00),
        undiscounted_price: Money.new(180_00),
      )
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
end
