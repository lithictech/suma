# frozen_string_literal: true

require "suma/postgres/model"
require "suma/mobility/vendor_adapter"

class Suma::Vendor::Service < Suma::Postgres::Model(:vendor_services)
  plugin :timestamps

  many_to_one :vendor, key: :vendor_id, class: "Suma::Vendor"
  many_to_many :categories, class: "Suma::Vendor::ServiceCategory",
                            join_table: :vendor_service_categories_vendor_services
  many_to_many :rates,
               class: "Suma::Vendor::ServiceRate",
               join_table: :vendor_service_vendor_service_rates,
               left_key: :vendor_service_id,
               right_key: :vendor_service_rate_id

  dataset_module do
    def mobility
      return self.with_category("mobility")
    end

    def with_category(slug)
      return self.where(categories: Suma::Vendor::ServiceCategory.where(slug:))
    end
  end

  def mobility_adapter
    return Suma::Mobility::VendorAdapter.create(self.mobility_vendor_adapter_key)
  end

  # Return the one and only rate for this service, or error if it has multiple rates.
  # In the future we will likely support determining rates per-resident,
  # but for now, we assume one rate for all residents using a service.
  def one_rate
    r = self.rates
    raise "#{self.inspect} has no rates" if r.empty?
    raise "#{self.inspect} has too many rates" if r.length > 1
    return r.first
  end
end
