# frozen_string_literal: true

require "suma/admin_linked"
require "suma/image"
require "suma/postgres/model"

class Suma::Program < Suma::Postgres::Model(:programs)
  include Suma::AdminLinked
  include Suma::Image::SingleAssociatedMixin

  plugin :timestamps
  plugin :tstzrange_fields, :period
  plugin :translated_text, :name, Suma::TranslatedText
  plugin :translated_text, :description, Suma::TranslatedText
  plugin :translated_text, :app_link_text, Suma::TranslatedText
  plugin :association_pks

  one_to_many :enrollments,
              class: "Suma::Program::Enrollment"

  many_to_many :vendor_services,
               class: "Suma::Vendor::Service",
               join_table: :programs_vendor_services,
               right_key: :service_id
  many_to_many :commerce_offerings,
               class: "Suma::Commerce::Offering",
               join_table: :programs_commerce_offerings,
               right_key: :offering_id
  many_to_many :anon_proxy_vendor_configurations,
               class: "Suma::AnonProxy::VendorConfiguration",
               join_table: :programs_anon_proxy_vendor_configurations,
               right_key: :configuration_id
  many_to_many :payment_triggers,
               class: "Suma::Payment::Trigger",
               join_table: :programs_payment_triggers,
               right_key: :trigger_id

  plugin :association_array_replacer, :vendor_services, :commerce_offerings

  dataset_module do
    def active(as_of:)
      return self.where { (lower(period) < as_of) & (upper(period) > as_of) }
    end
  end

  def enrollment_for(o, as_of:, include: :active)
    # Use datasets for these checks, since otherwise we'd need to load a bunch of organization memberships,
    # which could be very memory-intensive.
    ds = if o.is_a?(Suma::Member)
           self.enrollments_dataset.
             where(
               Sequel[member: o] |
                 Sequel[organization_id: o.organization_memberships_dataset.verified.select(:verified_organization_id)],
             )
    elsif o.is_a?(Suma::Organization)
      self.enrollments_dataset.where(organization: o)
    else
      raise TypeError, "unhandled type: #{o.class}"
    end
    ds = ds.active(as_of:) unless include == :all
    return ds.first
  end

  def rel_admin_link = "/program/#{self.id}"
end

require "suma/program/has"
