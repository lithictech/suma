# frozen_string_literal: true

require "suma/postgres/model"

class Suma::Vendor::ServiceRate < Suma::Postgres::Model(:vendor_service_rates)
  plugin :timestamps
  plugin :money_fields, :unit_amount, :surcharge

  many_to_many :services,
               class: "Suma::Vendor::Service",
               join_table: :vendor_service_vendor_service_rates,
               left_key: :vendor_service_rate_id,
               right_key: :vendor_service_id
  many_to_one :undiscounted_rate, key: :undiscounted_rate_id, class: "Suma::Vendor::ServiceRate"

  def calculate_total(units)
    offset_units = [units - self.unit_offset, 0].max
    t = self.unit_amount * offset_units
    t += self.surcharge
    return t
  end

  def calculate_undiscounted_total(units)
    r = self.undiscounted_rate_id.nil? ? self : self.undiscounted_rate
    return r.calculate_total(units)
  end

  def discount(units)
    disc = self.calculate_total(units)
    undisc = self.calculate_undiscounted_total(units)
    return undisc - disc
  end

  def discount_percentage(units)
    disc = self.calculate_total(units)
    undisc = self.calculate_undiscounted_total(units)
    f = 1 - (disc.to_f / undisc)
    return (f * 100).to_i
  end

  def message_template
    return "some_message_template"
  end

  def message_vars
    return {a: 5}
  end
end
