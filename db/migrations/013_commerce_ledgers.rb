# frozen_string_literal: true

Sequel.migration do
  change do
    create_join_table(
      {category_id: :vendor_service_categories, product_id: :commerce_products},
      name: :vendor_service_categories_commerce_products,
    )

    alter_table(:charges) do
      add_foreign_key :commerce_order_id, :commerce_orders, null: true, on_delete: :set_null, index: true
    end

    alter_table(:payment_ledgers) do
      add_foreign_key :contribution_text_id, :translated_texts, null: false
    end
  end
end
