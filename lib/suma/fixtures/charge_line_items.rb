# frozen_string_literal: true

require "suma/fixtures"
require "suma/charge/line_item"

module Suma::Fixtures::ChargeLineItems
  extend Suma::Fixtures

  fixtured_class Suma::Charge::LineItem

  base :charge_line_item do
  end

  before_saving do |instance|
    instance.charge ||= Suma::Fixtures.charge.create
    if instance.self_data_id.nil? && instance.book_transaction_id.nil?
      instance.self_data = Suma::Charge::LineItemSelfData.create(
        amount_cents: Faker::Number.between(from: 100, to: 100_00),
        amount_currency: "USD",
        memo: Suma::Fixtures.translated_text(all: Faker::Lorem.words(number: 3).join(" ")).create,
      )
    end
    instance
  end

  decorator :self_data do |opts={}|
    opts = Suma::Charge::LineItemSelfData.create(opts) unless opts.is_a?(Suma::Charge::LineItemSelfData)
    self.self_data = opts
  end

  decorator :book_transaction do |opts={}|
    opts = Suma::Fixtures.book_transaction.create(opts) unless opts.is_a?(Suma::Payment::BookTransaction)
    self.book_transaction = opts
  end
end
