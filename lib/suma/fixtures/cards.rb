# frozen_string_literal: true

require "suma/fixtures"
require "suma/payment/card"

module Suma::Fixtures::Cards
  extend Suma::Fixtures

  fixtured_class Suma::Payment::Card

  base :card do
    self.helcim_json ||= {
      "response" => "1",
      "responseMessage" => "APPROVED",
      "noticeMessage" => "Order Created - Customer Created",
      "date" => "2017-06-21",
      "time" => "12:23:31",
      "type" => "purchase",
      "amount" => "100.00",
      "cardHolderName" => "John Smith",
      "cardNumber" => "5454****5454",
      "cardExpiry" => "1025",
      "cardToken" => "5440c5e27f287875889421",
      "cardType" => "MasterCard",
      "transactionId" => "112415310",
      "avsResponse" => "X",
      "cvvResponse" => "M",
      "approvalCode" => "102542",
      "orderNumber" => "INV10010",
      "customerCode" => "CST2000",
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

  decorator :with_helcim do |j|
    self.helcim_json.merge!(j)
  end

  decorator :visa do
    self.helcim_json["cardType"] = "Visa"
    self.helcim_json["cardNumber"] = "4141****4141"
  end
end
