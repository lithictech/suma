# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:testing_pixies) do
      primary_key :id
      text :name
      tstzrange :active_during, null: false, default: "empty"
      integer :price_per_unit_cents, null: false, default: 0
      text :price_per_unit_currency, null: false, default: "USD"
    end

    create_table(:testing_secret_pixies) do
      primary_key :id
      integer :encryption_key_id
      bytea :secret_encrypted, null: false
    end
  end
end
