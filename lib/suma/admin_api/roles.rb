# frozen_string_literal: true

require "grape"

require "suma/admin_api"

class Suma::AdminAPI::Roles < Suma::AdminAPI::V1
  class RoleEntity < Suma::AdminAPI::Entities::RoleEntity; end
  class DetailedRoleEntity < RoleEntity; end

  resource :roles do
    desc "Return all roles, ordered by name"
    get do
      ds = Suma::Role.dataset.order(:name)
      present_collection ds, with: Suma::AdminAPI::Entities::RoleEntity
    end

    Suma::AdminAPI::CommonEndpoints.create(self, Suma::Role, DetailedRoleEntity) do
      params do
        requires :name, type: String, allow_blank: false
      end
    end

    Suma::AdminAPI::CommonEndpoints.get_one(self, Suma::Role, DetailedRoleEntity)

    Suma::AdminAPI::CommonEndpoints.update self, Suma::Role, DetailedRoleEntity do
      params do
        optional :name, type: String, allow_blank: false
      end
    end
  end
end
