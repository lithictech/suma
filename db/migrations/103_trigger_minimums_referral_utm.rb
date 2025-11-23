# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:payment_triggers) do
      add_column :unmatched_amount_cents, :integer, default: 0, null: false
    end
    alter_table(:member_referrals) do
      rename_column :channel, :source
      rename_column :event_name, :campaign
      add_column :medium, :text, null: false, default: ""
    end
  end
end
