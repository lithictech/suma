# frozen_string_literal: true

Sequel.migration do
  change do
    create_join_table({role_id: :roles, organization_id: :organizations}, name: :roles_organizations)
  end
end
