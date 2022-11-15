# frozen_string_literal: true

require "suma/commerce"
require "suma/postgres/model"

class Suma::Commerce::OfferingFulfillmentOption < Suma::Postgres::Model(:commerce_offering_fulfillment_options)
  plugin :timestamps
  plugin :translated_text, :description, Suma::TranslatedText

  many_to_one :address, class: "Suma::Address"
  many_to_one :offering, class: "Suma::Commerce::Offering"
end
