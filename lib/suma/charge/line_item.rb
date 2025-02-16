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
