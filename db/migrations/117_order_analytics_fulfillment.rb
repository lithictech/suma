# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(Sequel[:analytics][:orders]) do
      add_column :checkout_id, :integer
      add_column :card_id, :integer
      add_column :bank_account_id, :integer
      add_column :fulfillment_option_id, :integer
      add_column :fulfillment_option_address_id, :integer
      add_column :fulfillment_option_address, :text
      add_column :fulfillment_option_description, :text
    end
  end
end
