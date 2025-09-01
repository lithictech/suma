# frozen_string_literal: true

require "suma/postgres/model"

class Suma::Program::Pricing < Suma::Postgres::Model(:program_pricings)
  include Suma::AdminLinked

  plugin :timestamps

  many_to_one :program, class: "Suma::Program"
  many_to_one :vendor_service, class: "Suma::Vendor::Service"
  many_to_one :vendor_service_rate, class: "Suma::Vendor::ServiceRate"

  dataset_module do
    # Limit the result to pricings eligible to the member.
    # See +Suma::Program::Has#eligible_to+.
    def eligible_to(member, as_of:)
      programs = Suma::Program.where(enrollments: member.combined_program_enrollments_dataset.active(as_of:))
      ds = self.where(program: programs)
      return ds
    end

    # Limit the result such that the same vendor service is not repeated.
    # The row chosen from among duplicates is the row with the lowest vendor service rate ordinal.
    def compress
      ds = self.
        distinct(:vendor_service_id).
        association_join(:vendor_service_rate).
        reselect.
        order(:vendor_service_id, Sequel[:vendor_service_rate][:ordinal], Sequel[:vendor_service_rate][:id])
      return ds
    end
  end

  def rel_admin_link = "/program-pricing/#{self.id}"
end
