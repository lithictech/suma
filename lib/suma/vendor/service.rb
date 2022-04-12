# frozen_string_literal: true

require "suma/postgres/model"

class Suma::Vendor::Service < Suma::Postgres::Model(:vendor_services)
  plugin :timestamps

  many_to_one :vendor, key: :vendor_id, class: "Suma::Vendor"
  many_to_many :categories, class: "Suma::Vendor::ServiceCategory",
                            join_table: :vendor_service_categories_vendor_services
  many_to_many :rates, class: "Suma::Vendor::ServiceRate", join_table: :vendor_service_vendor_service_rates

  dataset_module do
    def mobility
      return self.with_category("mobility")
    end

    def with_category(slug)
      return self.where(categories: Suma::Vendor::ServiceCategory.where(slug:))
    end
  end
end
