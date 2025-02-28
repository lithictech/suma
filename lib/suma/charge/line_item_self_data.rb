# frozen_string_literal: true

require "suma/admin_linked"
require "suma/postgres/model"

class Suma::Charge::LineItemSelfData < Suma::Postgres::Model(:charge_line_item_self_datas)
  include Suma::AdminLinked

  plugin :money_fields, :amount
  plugin :translated_text, :memo, Suma::TranslatedText

  one_to_one :line_item, class: "Suma::Charge::LineItem"
end
