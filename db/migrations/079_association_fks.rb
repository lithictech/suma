# frozen_string_literal: true

Sequel.migration do
  # rubocop:disable Sequel/IrreversibleMigration
  change do
    [
      [:commerce_order_audit_logs, :order_id],
      [:commerce_products, :vendor_id],
      [:organization_membership_verification_audit_logs, :verification_id],
      [:organization_membership_verification_notes, :verification_id],
      [:payment_bank_accounts, :legal_entity_id],
      [:payment_cards, :legal_entity_id],
      [:payment_funding_transaction_audit_logs, :funding_transaction_id],
      [:payment_payout_transactions, :refunded_funding_transaction_id],
      [:payment_payout_transaction_audit_logs, :payout_transaction_id],
    ].each do |(tbl, col)|
      alter_table tbl do
        add_index col
      end
    end
  end
  # rubocop:enable Sequel/IrreversibleMigration
end
