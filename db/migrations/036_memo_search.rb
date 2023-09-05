# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:translated_texts) do
      add_column(
        :en_tsvector,
        :tsvector,
        null: false,
        generated_always_as: Sequel.function(:to_tsvector, "english", Sequel[:en]),
        index: {
          name: "en_tsvector_idx",
          type: "gin",
        },
      )
      add_column(
        :es_tsvector,
        :tsvector,
        null: false,
        generated_always_as: Sequel.function(:to_tsvector, "spanish", Sequel[:es]),
        index: {
          name: "es_tsvector_idx",
          type: "gin",
        },
      )
    end
  end
end
