# frozen_string_literal: true

require "suma/admin_api"

class Suma::AdminAPI::ProgramPricings < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  class DetailedProgramPricingEntity < ProgramPricingEntity
    include Suma::AdminAPI::Entities
    include AutoExposeDetail
  end

  resource :program_pricings do
    Suma::AdminAPI::CommonEndpoints.create(
      self,
      Suma::Program::Pricing,
      DetailedProgramPricingEntity,
      around: lambda do |_rt, m, &block|
        block.call
        m.program.audit_activity(
          "addpricing",
          action: "Created #{m.class.name}[#{m.id}]",
        )
      end,
    ) do
      params do
        requires(:program, type: JSON) { use :model_with_id }
        requires(:vendor_service, type: JSON) { use :model_with_id }
        requires(:vendor_service_rate, type: JSON) { use :model_with_id }
      end
    end

    Suma::AdminAPI::CommonEndpoints.get_one(
      self,
      Suma::Program::Pricing,
      DetailedProgramPricingEntity,
    )

    Suma::AdminAPI::CommonEndpoints.update(
      self,
      Suma::Program::Pricing,
      DetailedProgramPricingEntity,
      around: lambda do |_rt, m, &block|
        block.call
        m.program.audit_activity(
          "changepricing",
          action: "Updated #{Suma::HasActivityAudit.model_repr(m)} rate: " \
                  "#{Suma::HasActivityAudit.model_repr(m.vendor_service_rate)}",
        )
      end,
    ) do
      params do
        optional(:vendor_service_rate, type: JSON) { use :model_with_id }
      end
    end

    Suma::AdminAPI::CommonEndpoints.destroy(
      self,
      Suma::Program::Pricing,
      DetailedProgramPricingEntity,
      around: lambda do |rt, m, &block|
        block.call
        m.program.audit_activity("deletepricing", action: m)
        rt.created_resource_headers(m.program_id, m.program.admin_link)
      end,
    )
  end
end
