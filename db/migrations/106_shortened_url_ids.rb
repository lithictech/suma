# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:url_shortener) do
      add_column :id, :Bigserial, primary_key: true
    end
  end
end
