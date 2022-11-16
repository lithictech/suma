# frozen_string_literal: true

require "sequel/unambiguous_constraint"
require "sequel/nonempty_string_constraint"

Sequel.migration do
  up do
    alter_table(:payment_book_transactions) do
      drop_column :memo
      add_foreign_key :memo_id, :translated_texts, null: false
    end

    alter_table(:payment_funding_transactions) do
      drop_column :memo
      add_foreign_key :memo_id, :translated_texts, null: false
    end
  end
  down do
    alter_table(:payment_book_transactions) do
      drop_column :memo_id
      add_column :memo, :text, null: false, default: ""
    end

    alter_table(:payment_funding_transactions) do
      drop_column :memo_id
      add_column :memo, :text, null: false, default: ""
    end
  end
end
