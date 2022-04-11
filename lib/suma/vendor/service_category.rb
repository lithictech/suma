# frozen_string_literal: true

require "suma/postgres/model"

class Suma::Vendor::ServiceCategory < Suma::Postgres::Model(:vendor_service_categories)
  many_to_many :services, class: "Suma::Vendor::Service", join_table: :vendor_service_categories_vendor_services

  def before_create
    self.slug ||= Suma.to_slug(self.name)
  end
end
