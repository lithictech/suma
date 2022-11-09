# frozen_string_literal: true

require "suma/commerce"
require "suma/postgres/model"

class Suma::Commerce::Order < Suma::Postgres::Model(:commerce_orders)
  plugin :state_machine
  plugin :timestamps

  one_to_many :audit_logs, class: "Suma::Commerce::OrderAuditLog", order: Sequel.desc(:at)
  many_to_one :checkout, class: "Suma::Commerce::Checkout"

  state_machine :order_status, initial: :open do
    state :open

    after_transition(&:commit_audit_log)
    after_failure(&:commit_audit_log)
  end

  state_machine :fulfillment_status, initial: :unfulfilled do
    state :unfulfilled

    after_transition(&:commit_audit_log)
    after_failure(&:commit_audit_log)
  end
end
