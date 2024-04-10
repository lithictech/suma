# frozen_string_literal: true

require "grape"
require "suma/admin_api"

class Suma::AdminAPI::Organizations < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  resource :organizations do
    Suma::AdminAPI::CommonEndpoints.list(
      self,
      Suma::Organization,
      OrganizationEntity,
      search_params: [:name],
    )

    Suma::AdminAPI::CommonEndpoints.get_one(self, Suma::Organization, OrganizationEntity)

    Suma::AdminAPI::CommonEndpoints.create(self, Suma::Organization, OrganizationEntity) do
      params do
        requires :name, type: String, allow_blank: false
      end
    end

    Suma::AdminAPI::CommonEndpoints.update self, Suma::Organization, OrganizationEntity do
      params do
        optional :name, type: String, allow_blank: false
      end
    end
  end
end
