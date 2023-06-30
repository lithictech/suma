# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table(:commerce_offerings) do
      add_foreign_key :fulfillment_prompt_id, :translated_texts, null: true
      add_foreign_key :fulfillment_confirmation_id, :translated_texts, null: true
    end
    prompt_id = from(:translated_texts).insert(
      en: "How do you want to get your stuff?",
      es: "¿Cómo desea obtener sus cosas?",
    )
    confirm_id = from(:translated_texts).insert(
      en: "How you’re getting it",
      es: "Cómo lo está recibiendo",
    )
    from(:commerce_offerings).update(
      fulfillment_prompt_id: prompt_id,
      fulfillment_confirmation_id: confirm_id,
    )
    alter_table(:commerce_offerings) do
      set_column_not_null :fulfillment_prompt_id
      set_column_not_null :fulfillment_confirmation_id
    end
  end
  down do
    alter_table(:commerce_offerings) do
      drop_column :fulfillment_prompt_id
      drop_column :fulfillment_confirmation_id
    end
  end
end
