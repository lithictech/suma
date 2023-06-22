# frozen_string_literal: true

require "rake"
require "suma/tasks/bootstrap"

RSpec.describe "Suma::Tasks::Bootstrap", :db do
  let(:described_class) { Suma::Tasks::Bootstrap }

  describe "setup_market_offering_product" do
    let(:market_name) { "St. Johns Farmers Market" }

    it "creates OfferingProduct successfully" do
      bootstrap = described_class.new
      bootstrap.setup_market_offering_product

      offering = Suma::Commerce::Offering.find(confirmation_template: "2023-07-pilot-confirmation")
      description = Suma::TranslatedText.find(en: "Suma Farmers Market Ride & Shop")
      uploaded_file = Suma::UploadedFile.find(filename: "st-johns-farmers-market-logo.png")
      offering_image = Suma::Image.find(uploaded_file:)
      address = Suma::Address.find(address1: "N Charleston Avenue &, N Central Street")

      name = Suma::TranslatedText.find(en: "$24 Token")
      product = Suma::Commerce::Product.find(name:)
      vendor = Suma::Vendor.find(name: market_name)
      uploaded_file = Suma::UploadedFile.find(filename: "suma-voucher-front.jpg")
      product_image = Suma::Image.find(uploaded_file:)
      inventory = Suma::Commerce::ProductInventory.find(product:)

      expect(offering).to have_attributes(description:, images: [offering_image], fulfillment_options: contain_exactly(
        have_attributes(address:, offering:),
      ),)
      expect(product).to have_attributes(our_cost_cents: 2400, vendor:, images: [product_image], inventory:)
      expect(inventory).to have_attributes(max_quantity_per_order: 1, max_quantity_per_offering: 50)
      expect(Suma::Commerce::OfferingProduct.find(offering:, product:)).to have_attributes(
        customer_price_cents: 2400, undiscounted_price_cents: 2400,
      )
    end
  end
end
