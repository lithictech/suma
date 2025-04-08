# frozen_string_literal: true

require "sequel/all_or_none_constraint"
require "sequel/unambiguous_constraint"

Sequel.migration do
  up do
    alter_table(:organization_memberships) do
      add_foreign_key :former_organization_id, :organizations, index: true
      add_column :formerly_in_organization_at, :timestamptz
      drop_constraint(:unambiguous_verification_status)
      add_constraint(
        :unambiguous_verification_status,
        Sequel.unambiguous_constraint([:verified_organization_id, :former_organization_id,
                                       :unverified_organization_name,]),
      )
      add_constraint(
        :unambiguous_former_organization,
        Sequel.all_or_none_constraint([:former_organization_id, :formerly_in_organization_at]),
      )
    end
  end
  down do
    alter_table(:organization_memberships) do
      drop_column :former_organization_id
      drop_column :formerly_in_organization_at
      add_constraint(
        :unambiguous_verification_status,
        Sequel.unambiguous_constraint([:verified_organization_id, :unverified_organization_name]),
      )
    end
  end
end
