# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:payment_book_transactions) do
      add_foreign_key :actor_id, :members, on_delete: :set_null
    end
  end
end
