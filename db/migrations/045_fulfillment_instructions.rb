# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:commerce_offerings) do
      add_foreign_key :fulfillment_instructions_id, :translated_texts, null: false
    end
  end
end
