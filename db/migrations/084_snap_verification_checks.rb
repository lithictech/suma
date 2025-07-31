# frozen_string_literal: true

require "sequel/null_or_present_constraint"

Sequel.migration do
  change do
    alter_table(:members) do
      add_column :previous_phones, :"text[]", null: false, default: "{}"
      add_column :previous_emails, :"text[]", null: false, default: "{}"
    end

    alter_table(:organization_membership_verifications) do
      add_column :account_number, :text, null: true
      add_constraint :non_empty_account_number, Sequel.null_or_present_constraint(:account_number)
    end
  end
end
