# frozen_string_literal: true

require "suma/admin_linked"
require "suma/postgres/model"

# See +Suma::Charge+ for an explanation of how line items work,
# especially with +book_transaction+ vs. +self_data+.
class Suma::Charge::LineItem < Suma::Postgres::Model(:charge_line_items)
  include Suma::AdminLinked

  plugin :timestamps

  many_to_one :charge, class: "Suma::Charge"
  many_to_one :book_transaction, class: "Suma::Payment::BookTransaction"
  many_to_one :self_data, class: "Suma::Charge::LineItemSelfData"

  def self.create_self(amount:, memo:, **kw)
    self.db.transaction do
      self_data = Suma::Charge::LineItemSelfData.create(amount:, memo:)
      return self.create(self_data:, **kw)
    end
  end

  def initialize(*)
    super
    self.opaque_id ||= Suma::Secureid.new_opaque_id("chi")
  end

  def rel_admin_link = "/charge-line-item/#{self.id}"

  def amount = self.self_data&.amount || self.book_transaction.amount
  def memo = self.self_data&.memo || self.book_transaction.memo
end

# Table: charge_line_items
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------
# Columns:
#  id                  | integer                  | PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY
#  created_at          | timestamp with time zone | NOT NULL DEFAULT now()
#  updated_at          | timestamp with time zone |
#  opaque_id           | text                     | NOT NULL
#  charge_id           | integer                  | NOT NULL
#  book_transaction_id | integer                  |
#  self_data_id        | integer                  |
# Indexes:
#  charge_line_items_pkey                    | PRIMARY KEY btree (id)
#  charge_line_items_book_transaction_id_key | UNIQUE btree (book_transaction_id)
#  charge_line_items_opaque_id_key           | UNIQUE btree (opaque_id)
#  charge_line_items_self_data_id_key        | UNIQUE btree (self_data_id)
#  charge_line_items_charge_id_index         | btree (charge_id)
# Check constraints:
#  self_data_or_book_transaction_data_set | (book_transaction_id IS NOT NULL AND self_data_id IS NULL OR book_transaction_id IS NULL AND self_data_id IS NOT NULL)
# Foreign key constraints:
#  charge_line_items_book_transaction_id_fkey | (book_transaction_id) REFERENCES payment_book_transactions(id) ON DELETE RESTRICT
#  charge_line_items_charge_id_fkey           | (charge_id) REFERENCES charges(id) ON DELETE CASCADE
#  charge_line_items_self_data_id_fkey        | (self_data_id) REFERENCES charge_line_item_self_datas(id) ON DELETE RESTRICT
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------
