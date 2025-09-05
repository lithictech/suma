# frozen_string_literal: true

require "sequel/unambiguous_constraint"

Sequel.migration do
  tables = [
    :anon_proxy_member_contacts,
    :anon_proxy_vendor_accounts,
    :programs,
    :anon_proxy_vendor_configurations,
    :charges,
    :commerce_offerings,
    :commerce_orders,
    :vendors,
    :commerce_products,
    :marketing_lists,
    :marketing_sms_broadcasts,
    :marketing_sms_dispatches,
    :members,
    :message_deliveries,
    :mobility_trips,
    :organizations,
    :organization_memberships,
    :organization_membership_verifications,
    :payment_bank_accounts,
    :payment_book_transactions,
    :payment_cards,
    :payment_funding_transactions,
    :payment_payout_transactions,
    :program_enrollments,
    :payment_ledgers,
    :payment_triggers,
    :vendor_services,
  ]

  # rubocop:disable Sequel/IrreversibleMigration
  change do
    tables.each do |tbl|
      alter_table(tbl) do
        add_index :search_content,
                  name: :"#{tbl}_search_content_trigram_index",
                  type: :gist
      end
    end
    # rubocop:enable Sequel/IrreversibleMigration
  end
end
