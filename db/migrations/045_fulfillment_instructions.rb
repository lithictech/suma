# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table(:commerce_offerings) do
      add_foreign_key :fulfillment_instructions_id, :translated_texts, null: true
    end
    if ENV["RACK_ENV"] != "test"
      fulfillment_instructions_id = from(:translated_texts).insert(en: "", es: "")
      from(:commerce_offerings).update(fulfillment_instructions_id:)
    end
    alter_table(:commerce_offerings) do
      set_column_not_null :fulfillment_instructions_id
    end
  end
  down do
    alter_table(:commerce_offerings) do
      drop_column :fulfillment_instructions_id
    end
  end
end
