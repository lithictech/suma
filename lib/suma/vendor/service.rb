# frozen_string_literal: true

require "suma/eligibility/has_constraints"
require "suma/mobility/vendor_adapter"
require "suma/postgres/model"
require "suma/image"
require "suma/vendor/has_service_categories"

class Suma::Vendor::Service < Suma::Postgres::Model(:vendor_services)
  include Suma::Image::AssociatedMixin

  plugin :timestamps
  plugin :tstzrange_fields, :period

  many_to_many :vendible_groups,
               class: "Suma::Vendible::Group",
               join_table: :vendible_groups_vendor_services,
               left_key: :service_id,
               right_key: :group_id

  many_to_one :vendor, key: :vendor_id, class: "Suma::Vendor"

  many_to_many :categories, class: "Suma::Vendor::ServiceCategory",
                            join_table: :vendor_service_categories_vendor_services
  def vendor_service_categories = self.categories
  include Suma::Vendor::HasServiceCategories

  many_to_many :rates,
               class: "Suma::Vendor::ServiceRate",
               join_table: :vendor_service_vendor_service_rates,
               left_key: :vendor_service_id,
               right_key: :vendor_service_rate_id

  many_to_many :eligibility_constraints,
               class: "Suma::Eligibility::Constraint",
               join_table: :eligibility_vendor_service_associations,
               right_key: :constraint_id,
               left_key: :service_id
  include Suma::Eligibility::HasConstraints

  dataset_module do
    def mobility
      return self.with_category("mobility")
    end

    def with_category(slug)
      return self.where(categories: Suma::Vendor::ServiceCategory.where(slug:))
    end

    def available_at(t)
      return self.where(Sequel.pg_range(:period).contains(Sequel.cast(t, :timestamptz)))
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

  # A hash is said to satisfy the vendor service constraints
  # if any of the constraints have all of their keys and values present in the hash.
  #
  # For example, given constraints of
  #   [{'a' => 1}, {'b' => 2}, {'a' => 3}]
  # the hashes {'a' => 1} and {'a' => 2, 'b' => 2} are satisfied,
  # while {'a' => 2} is not.
  #
  # Any hash is satisfied by empty constraints.
  # An empty hash can only be satisfied by empty constraints.
  def satisfies_constraints?(hash)
    return true if self.constraints.empty?
    return self.constraints.any? do |constraint|
      constraint.all? { |k, v| hash[k] == v && hash.key?(k) }
    end
  end

  def rel_app_link = "/mobility"
end

# Table: vendor_services
# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Columns:
#  id                          | integer                  | PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY
#  created_at                  | timestamp with time zone | NOT NULL DEFAULT now()
#  updated_at                  | timestamp with time zone |
#  vendor_id                   | integer                  | NOT NULL
#  internal_name               | text                     | NOT NULL
#  external_name               | text                     | NOT NULL
#  mobility_vendor_adapter_key | text                     | NOT NULL DEFAULT ''::text
#  constraints                 | jsonb                    | DEFAULT '[]'::jsonb
# Indexes:
#  vendor_services_pkey            | PRIMARY KEY btree (id)
#  vendor_services_vendor_id_index | btree (vendor_id)
# Foreign key constraints:
#  vendor_services_vendor_id_fkey | (vendor_id) REFERENCES vendors(id) ON DELETE CASCADE
# Referenced By:
#  eligibility_vendor_service_associations   | eligibility_vendor_service_associations_service_id_fkey    | (service_id) REFERENCES vendor_services(id)
#  mobility_restricted_areas                 | mobility_restricted_areas_vendor_service_id_fkey           | (vendor_service_id) REFERENCES vendor_services(id)
#  mobility_trips                            | mobility_trips_vendor_service_id_fkey                      | (vendor_service_id) REFERENCES vendor_services(id) ON DELETE RESTRICT
#  mobility_vehicles                         | mobility_vehicles_vendor_service_id_fkey                   | (vendor_service_id) REFERENCES vendor_services(id) ON DELETE CASCADE
#  vendor_service_categories_vendor_services | vendor_service_categories_vendor_services_service_id_fkey  | (service_id) REFERENCES vendor_services(id)
#  vendor_service_vendor_service_rates       | vendor_service_vendor_service_rates_vendor_service_id_fkey | (vendor_service_id) REFERENCES vendor_services(id)
# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
