# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:programs) do
      add_column :lyft_pass_program_id, :text, null: false, default: ""
    end
  end
end
