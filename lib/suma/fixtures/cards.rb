# frozen_string_literal: true

require "suma/fixtures"
require "suma/payment/card"

module Suma::Fixtures::Cards
  extend Suma::Fixtures

  fixtured_class Suma::Payment::Card

  base :card do
    self.stripe_json ||= {
      "id" => "card_1LxbQmAqRmWQecssc7Yf9Wr7",
      "object" => "card",
      "address_city" => nil,
      "address_country" => nil,
      "address_line1" => nil,
      "address_line1_check" => nil,
      "address_line2" => nil,
      "address_state" => nil,
      "address_zip" => nil,
      "address_zip_check" => nil,
      "brand" => "Visa",
      "country" => "US",
      "customer" => "cus_cardowner",
      "cvc_check" => "pass",
      "dynamic_last4" => nil,
      "exp_month" => 8,
      "exp_year" => Time.now.year + 1,
      "fingerprint" => "vIjZVstYyGmkvbVe",
      "funding" => "credit",
      "last4" => "4242",
      "metadata" => {},
      "name" => nil,
      "tokenization_method" => nil,
    }
  end

  before_saving do |instance|
    instance.legal_entity ||= Suma::Fixtures.legal_entity.create
    instance
  end

  decorator :member do |c={}|
    c = Suma::Fixtures.member(c).create unless c.is_a?(Suma::Member)
    self.legal_entity = c.legal_entity
  end

  decorator :with_legal_entity do |le={}|
    le = Suma::Fixtures.legal_entity(le).create unless le.is_a?(Suma::LegalEntity)
    self.legal_entity = le
  end

  decorator :with_stripe do |j|
    self.stripe_json.merge!(j)
  end

  decorator :visa do
    self.stripe_json["brand"] = "Visa"
    self.stripe_json["last4"] = "4242"
  end

  decorator :expired do |month: Time.now.month, year: Time.now.year|
    self.stripe_json["exp_month"] = month
    self.stripe_json["exp_year"] = year
  end

  decorator :usable do
  end

  decorator :unusable do
    self.stripe_json["exp_year"] = Time.now.year - 1
  end
end
