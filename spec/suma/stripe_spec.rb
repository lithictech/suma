# frozen_string_literal: true

require "suma/stripe"
require "suma/service"

RSpec.describe Suma::Stripe, :db do
  it "uses only valid error codes" do
    codes = described_class::ERRORS_FOR_CODES.keys
    codes.each do |code|
      declinebody = {"error" => {"code" => "card_declined", "decline_code" => code, "type" => "card_error"}}
      err = Stripe::CardError.new("testing", "p", json_body: declinebody)
      expect(Suma::I18n.localized_error_codes).to be_include(described_class.localized_error_code(err))

      errbody = {"error" => {"code" => code, "type" => "card_error"}}
      err = Stripe::CardError.new("testing", "p", json_body: errbody)
      expect(Suma::I18n.localized_error_codes).to be_include(described_class.localized_error_code(err))
    end
  end

  describe "build_metadata" do
    it "builds metadata for models" do
      v = Suma::Fixtures.vendor.create
      bx = Suma::Fixtures.book_transaction.create
      expect(described_class.build_metadata).to eq({suma_api_version: "unknown-version"})
      expect(described_class.build_metadata([v, nil])).to eq(
        {
          suma_api_version: "unknown-version",
          suma_vendor_id: v.id,
          suma_vendor_name: v.name,
        },
      )
      expect(described_class.build_metadata([v, bx])).to eq(
        {
          suma_api_version: "unknown-version",
          suma_vendor_id: v.id,
          suma_vendor_name: v.name,
          suma_book_transaction_id: bx.id,
        },
      )
    end
  end
end
