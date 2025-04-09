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
    alter_table(:anon_proxy_member_contacts) do
      add_column :search_content, :text
      add_column :search_embedding, "vector(384)"
      add_column :search_hash, :text
      add_index Sequel.function(:to_tsvector, "english", :search_content),
                name: :anon_proxy_member_contacts_search_content_tsvector_index,
                type: :gin
    end
  end
  down do
    from(:organization_memberships).where(unverified_organization_name: nil, verified_organization_id: nil).delete
    alter_table(:organization_memberships) do
      drop_column :former_organization_id
      drop_column :formerly_in_organization_at
      add_constraint(
        :unambiguous_verification_status,
        Sequel.unambiguous_constraint([:verified_organization_id, :unverified_organization_name]),
      )
    end
    alter_table(:anon_proxy_member_contacts) do
      drop_column :search_content
      drop_column :search_embedding
      drop_column :search_hash
    end
  end
end
