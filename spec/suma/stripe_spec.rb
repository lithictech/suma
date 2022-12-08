# frozen_string_literal: true

require "suma/stripe"
require "suma/service"

RSpec.describe Suma::Stripe, :db do
  it "uses only valid error codes" do
    codes = described_class::ERRORS_FOR_CODES.keys
    codes.each do |code|
      declinebody = {"error" => {"code" => "card_declined", "decline_code" => code, "type" => "card_error"}}
      err = Stripe::CardError.new("testing", "p", json_body: declinebody)
      expect(Suma::Service.localized_error_codes).to be_include(described_class.localized_error_code(err))

      errbody = {"error" => {"code" => code, "type" => "card_error"}}
      err = Stripe::CardError.new("testing", "p", json_body: errbody)
      expect(Suma::Service.localized_error_codes).to be_include(described_class.localized_error_code(err))
    end
  end
end
