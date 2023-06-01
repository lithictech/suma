# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table(:member_referral) do
      drop_index :member_id
    end

    rename_table(:member_referral, :member_referrals)

    alter_table(:member_referrals) do
      add_index :member_id, unique: true
    end
  end

  down do
    alter_table(:member_referrals) do
      drop_index :member_id
    end

    rename_table(:member_referrals, :member_referral)

    alter_table(:member_referral) do
      add_index :member_id
    end
  end
end
