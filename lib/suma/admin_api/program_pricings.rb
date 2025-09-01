# frozen_string_literal: true

require "suma/admin_api"

class Suma::AdminAPI::ProgramPricings < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  class DetailedProgramPricingEntity < ProgramPricingEntity
    include Suma::AdminAPI::Entities
    include AutoExposeDetail
  end

  resource :program_pricings do
    helpers do
      def modelrepr(m)
        prefix = Suma::HasActivityAudit.model_repr(m)
        "#{prefix}(service: '#{m.vendor_service.internal_name}', rate: '#{m.vendor_service_rate.name}')"
      end
    end

    Suma::AdminAPI::CommonEndpoints.create(
      self,
      Suma::Program::Pricing,
      DetailedProgramPricingEntity,
      around: lambda do |rt, m, &block|
        block.call
        m.program.audit_activity("addpricing", action: rt.modelrepr(m))
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
      around: lambda do |rt, m, &block|
        block.call
        m.program.audit_activity("changepricing", action: rt.modelrepr(m))
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
        m.program.audit_activity("deletepricing", action: rt.modelrepr(m))
        rt.created_resource_headers(m.program_id, m.program.admin_link)
      end,
    )
  end
end
