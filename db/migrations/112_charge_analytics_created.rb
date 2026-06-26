# frozen_string_literal: true

Sequel.migration do
  # These FK columns should use ON DELETE CASCADE, not the default/restrict
  fks_to_cascade = [
    [:charges, :member_id, :members],
    [:commerce_carts, :member_id, :members],
    [:commerce_cart_items, :cart_id, :commerce_carts],
    [:commerce_cart_items, :product_id, :commerce_products],
    [:commerce_order_audit_logs, :order_id, :commerce_orders],
    [:member_reset_codes, :member_id, :members],
    [:message_preferences, :member_id, :members],
    [:mobility_trips, :member_id, :members],
    [:organization_memberships, :member_id, :members],
    [:organization_membership_verifications, :membership_id, :organization_memberships],
  ]
  up do
    alter_table(Sequel[:analytics][:charges]) do
      add_column :incurred_at, :timestamptz
    end
    fks_to_cascade.each do |tbl, col, foreign|
      alter_table tbl do
        drop_foreign_key [col]
        add_foreign_key [col], foreign, on_delete: :cascade
      end
    end
  end

  down do
    alter_table(Sequel[:analytics][:charges]) do
      drop_column :incurred_at
    end
    fks_to_cascade.each do |tbl, col, foreign|
      alter_table tbl do
        drop_foreign_key [col]
        add_foreign_key [col], foreign
      end
    end
  end
end
