# frozen_string_literal: true

Sequel.migration do
  tables = [
    :anon_proxy_vendor_accounts,
    :charges,
    :commerce_offerings,
    :commerce_products,
    :members,
    :message_deliveries,
    :mobility_trips,
    :organizations,
    :payment_book_transactions,
    :payment_funding_transactions,
    :payment_ledgers,
    :payment_payout_transactions,
    :payment_triggers,
    :programs,
    :vendor_services,
    :vendors,
  ]
  up do
    run "CREATE EXTENSION IF NOT EXISTS vector"
    tables.each do |tbl|
      alter_table(tbl) do
        add_column :search_content, :text
        add_column :search_embedding, "vector(384)"
        add_column :search_hash, :text
        add_index Sequel.function(:to_tsvector, "english", :search_content),
                  name: :"#{tbl}_search_content_tsvector_index",
                  using: :gin
      end
    end
  end
  down do
    tables.each do |tbl|
      alter_table(tbl) do
        drop_column :search_content
        drop_column :search_embedding
        drop_column :search_hash
        drop_column :search_tsvector
      end
    end
  end
end
