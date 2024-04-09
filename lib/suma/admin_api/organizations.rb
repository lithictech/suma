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
  end
end
