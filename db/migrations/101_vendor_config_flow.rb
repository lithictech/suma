# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table(:anon_proxy_vendor_configurations) do
      add_foreign_key :description_text_id, :translated_texts
      add_foreign_key :help_text_id, :translated_texts
    end
    from(:anon_proxy_vendor_configurations).update(
      description_text_id: :instructions_id,
      help_text_id: :instructions_id,
    )
    alter_table(:anon_proxy_vendor_configurations) do
      set_column_not_null :description_text_id
      set_column_not_null :help_text_id
      rename_column :instructions_id, :terms_text_id
    end
  end
  down do
    alter_table(:anon_proxy_vendor_configurations) do
      drop_column :description_text_id
      drop_column :help_text_id
      rename_column :terms_text_id, :instructions_id
    end
  end
end
