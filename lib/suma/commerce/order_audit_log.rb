# frozen_string_literal: true

require "suma/postgres/model"

class Suma::Payment::OrderAuditLog < Suma::Postgres::Model(:commerce_order_audit_logs)
  plugin :state_machine_audit_log

  many_to_one :order, class: "Suma::Commerce::Order"
  many_to_one :actor, class: "Suma::Member"
end
