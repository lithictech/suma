# frozen_string_literal: true

require "grape"

require "suma/admin_api"

class Suma::AdminAPI::Roles < Suma::AdminAPI::V1
  resource :roles do
    desc "Return all roles, ordered by name"
    get do
      ds = Suma::Role.dataset.order(:name)
      present_collection ds, with: Suma::AdminAPI::Entities::RoleEntity
    end
  end
end
