# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:i18n_static_strings) do
      add_index :modified_at
      add_index :text_id, unique: true # Should never be shared
    end
  end
end
