# frozen_string_literal: true

Sequel.migration do
  up do
    # This is a prerelease migration so we aren't bothering migrating data.
    from(:images).delete
    from(:commerce_offering_products).delete
    from(:commerce_products).delete
    from(:commerce_offerings).delete

    create_table(:translated_texts) do
      primary_key :id
      timestamptz :created_at, null: false, default: Sequel.function(:now)
      text :en, null: false, default: ""
      text :es, null: false, default: ""
    end

    alter_table(:commerce_products) do
      add_foreign_key :name_id, :translated_texts, null: false
      add_foreign_key :description_id, :translated_texts, null: false
      drop_column :name
      drop_column :description
    end

    alter_table(:commerce_offerings) do
      add_foreign_key :description_id, :translated_texts, null: false
      drop_column :description
    end

    alter_table(:images) do
      add_foreign_key :caption_id, :translated_texts, null: false
      drop_column :caption
    end
  end

  down do
    # This is a prerelease migration so we aren't bothering migrating data.
    from(:images).delete
    from(:commerce_offering_products).delete
    from(:commerce_products).delete
    from(:commerce_offerings).delete

    alter_table(:commerce_products) do
      add_column :name, :text, null: false, default: ""
      add_column :description, :text, null: false, default: ""
      drop_column :name_id
      drop_column :description_id
    end

    alter_table(:commerce_offerings) do
      add_column :description, :text, null: false, default: ""
      drop_column :description_id
    end

    alter_table(:images) do
      add_column :caption, :text, null: false, default: ""
      drop_column :caption_id
    end

    drop_table(:translated_texts)
  end
end
