# frozen_string_literal: true

require "suma/admin_api"

class Suma::AdminAPI::AnonProxyVendorConfigurations < Suma::AdminAPI::V1
  include Suma::Service::Types
  include Suma::AdminAPI::Entities

  class DetailedVendorConfigurationEntity < AnonProxyVendorConfigurationEntity
    include Suma::AdminAPI::Entities
    include AutoExposeDetail
    expose :audit_activities, with: ActivityEntity
    expose :programs, with: ProgramEntity
    expose :description_text, with: TranslatedTextEntity
    expose :help_text, with: TranslatedTextEntity
    expose :terms_text, with: TranslatedTextEntity
    expose :linked_success_instructions, with: TranslatedTextEntity
  end

  resource :anon_proxy_vendor_configurations do
    Suma::AdminAPI::CommonEndpoints.list(
      self,
      Suma::AnonProxy::VendorConfiguration,
      AnonProxyVendorConfigurationEntity,
    )

    Suma::AdminAPI::CommonEndpoints.get_one(
      self,
      Suma::AnonProxy::VendorConfiguration,
      DetailedVendorConfigurationEntity,
    )

    Suma::AdminAPI::CommonEndpoints.update(
      self,
      Suma::AnonProxy::VendorConfiguration,
      DetailedVendorConfigurationEntity,
    ) do
      params do
        optional :enabled, type: Boolean
        optional :app_install_link, type: String
        optional(:description_text, type: JSON) { use :translated_text }
        optional(:help_text, type: JSON) { use :translated_text }
        optional(:terms_text, type: JSON) { use :translated_text }
        optional(:linked_success_instructions, type: JSON) { use :translated_text }
      end
    end

    Suma::AdminAPI::CommonEndpoints.programs_update(
      self,
      Suma::AnonProxy::VendorConfiguration,
      DetailedVendorConfigurationEntity,
    )
  end
end
