# frozen_string_literal: true

Sequel.migration do
  tables = [
    :anon_proxy_vendor_configurations,
    :commerce_orders,
    :organization_memberships,
    :program_enrollments,
  ]
  # rubocop:disable Sequel/IrreversibleMigration
  change do
    tables.each do |tbl|
      alter_table(tbl) do
        add_column :search_content, :text
        add_column :search_embedding, "vector(384)"
        add_column :search_hash, :text
        add_index Sequel.function(:to_tsvector, "english", :search_content),
                  name: :"#{tbl}_search_content_tsvector_index",
                  type: :gin
      end
    end
  end
  # rubocop:enable Sequel/IrreversibleMigration
end
