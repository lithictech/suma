# frozen_string_literal: true

require "suma/admin_linked"
require "suma/image"
require "suma/has_activity_audit"
require "suma/mobility/vendor_adapter"
require "suma/postgres/model"
require "suma/vendor/has_service_categories"

class Suma::Vendor::Service < Suma::Postgres::Model(:vendor_services)
  include Suma::Postgres::HybridSearch
  include Suma::AdminLinked
  include Suma::Image::SingleAssociatedMixin
  include Suma::HasActivityAudit

  plugin :hybrid_search
  plugin :timestamps
  plugin :tstzrange_fields, :period
  plugin :association_pks

  many_to_one :vendor, key: :vendor_id, class: "Suma::Vendor"

  many_to_many :categories,
               class: "Suma::Vendor::ServiceCategory",
               join_table: :vendor_service_categories_vendor_services,
               order: order_desc(:slug)
  def vendor_service_categories = self.categories
  include Suma::Vendor::HasServiceCategories

  one_to_many :mobility_trips, class: "Suma::Mobility::Trip", key: :vendor_service_id, order: order_desc
  one_to_one :mobility_adapter, class: "Suma::Mobility::VendorAdapter", key: :vendor_service_id

  one_to_many :program_pricings,
              class: "Suma::Program::Pricing",
              key: :vendor_service_id,
              order: order_desc

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

  # Raise a +Suma::Member::ReadOnlyMode+ error there is a +usage_prohibited_reason+.
  # This should generally be called before starting to use the service.
  def guard_usage!(member, rate:, now:)
    return unless (reason = self.usage_prohibited_reason(member, rate:, now:))
    raise Suma::Member::ReadOnlyMode, reason
  end

  # Return the reason why usage is prohibited, or nil if usage is allowed.
  # For example, a negative balance may prohibit usage.
  def usage_prohibited_reason(member, rate:, now:)
    return member.read_only_reason if member.read_only_reason
    return "usage_prohibited_cash_balance" unless Suma::Payment.can_use_services?(member.payment_account, now:)
    instrument_required = (rate.surcharge_cents.positive? || rate.unit_amount_cents.positive?) &&
      member.default_payment_instrument.nil?
    return "usage_prohibited_instrument_required" if instrument_required
    return nil
  end

  def mobility_adapter_setting_options
    return [
      {name: "No Adapter/Non-Mobility", value: "no_adapter"},
      {name: "Deep Linking (suma sends receipts)", value: "deep_linking_suma_receipts"},
      {name: "Deep Linking (vendor sends receipts)", value: "deep_linking_vendor_receipts"},
    ].concat(
      Suma::Mobility::TripProvider.registered_keys.map do |value|
        {name: "MaaS: #{value}", value:}
      end,
    )
  end

  def mobility_adapter_setting
    return "no_adapter" if self.mobility_adapter.nil?
    if self.mobility_adapter.uses_deep_linking?
      return "deep_linking_suma_receipts" if self.mobility_adapter.send_receipts?
      return "deep_linking_vendor_receipts"
    end
    return self.mobility_adapter.trip_provider_key
  end

  def mobility_adapter_setting_name
    self.mobility_adapter_setting_options.find { |h| h[:value] == self.mobility_adapter_setting }.fetch(:name)
  end

  def mobility_adapter_setting=(value)
    case value
      when "no_adapter"
        self.mobility_adapter&.destroy
        self.associations[:mobility_adapter] = nil
      when "deep_linking_suma_receipts"
        self.ensure_mobility_adapter.configure_deep_linking(send_receipts: true).save_changes
      when "deep_linking_vendor_receipts"
        self.ensure_mobility_adapter.configure_deep_linking(send_receipts: false).save_changes
      else
        self.ensure_mobility_adapter.configure_trip_provider(value).save_changes
    end
  end

  def ensure_mobility_adapter
    if self.mobility_adapter.nil?
      Suma::Mobility::VendorAdapter.find_or_create_or_find(vendor_service: self) do |a|
        # Need to give it some default.
        a.uses_deep_linking = true
      end
    end
    return self.mobility_adapter
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

  def rel_admin_link = "/vendor-service/#{self.id}"

  def rel_app_link = "/mobility"

  def hybrid_search_fields
    return [
      :internal_name,
      :external_name,
      :period_begin,
      :period_end,
      :vendor,
    ]
  end
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
#  period                      | tstzrange                | NOT NULL
#  charge_after_fulfillment    | boolean                  | NOT NULL DEFAULT false
#  search_content              | text                     |
#  search_embedding            | vector(384)              |
#  search_hash                 | text                     |
# Indexes:
#  vendor_services_pkey                          | PRIMARY KEY btree (id)
#  vendor_services_search_content_tsvector_index | gin (to_tsvector('english'::regconfig, search_content))
#  vendor_services_vendor_id_index               | btree (vendor_id)
# Foreign key constraints:
#  vendor_services_vendor_id_fkey | (vendor_id) REFERENCES vendors(id) ON DELETE CASCADE
# Referenced By:
#  eligibility_vendor_service_associations   | eligibility_vendor_service_associations_service_id_fkey    | (service_id) REFERENCES vendor_services(id)
#  images                                    | images_vendor_service_id_fkey                              | (vendor_service_id) REFERENCES vendor_services(id)
#  mobility_restricted_areas                 | mobility_restricted_areas_vendor_service_id_fkey           | (vendor_service_id) REFERENCES vendor_services(id)
#  mobility_trips                            | mobility_trips_vendor_service_id_fkey                      | (vendor_service_id) REFERENCES vendor_services(id) ON DELETE RESTRICT
#  mobility_vehicles                         | mobility_vehicles_vendor_service_id_fkey                   | (vendor_service_id) REFERENCES vendor_services(id) ON DELETE CASCADE
#  programs                                  | programs_vendor_service_id_fkey                            | (vendor_service_id) REFERENCES vendor_services(id)
#  programs_vendor_services                  | programs_vendor_services_service_id_fkey                   | (service_id) REFERENCES vendor_services(id)
#  vendible_groups_vendor_services           | vendible_groups_vendor_services_service_id_fkey            | (service_id) REFERENCES vendor_services(id)
#  vendor_service_categories_vendor_services | vendor_service_categories_vendor_services_service_id_fkey  | (service_id) REFERENCES vendor_services(id)
#  vendor_service_vendor_service_rates       | vendor_service_vendor_service_rates_vendor_service_id_fkey | (vendor_service_id) REFERENCES vendor_services(id)
# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
