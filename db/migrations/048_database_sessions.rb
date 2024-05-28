# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table(:member_sessions) do
      add_column :token, :text, unique: true
      add_column :logged_out_at, :timestamptz
      add_foreign_key :impersonating_id, :members, on_delete: :set_null
    end

    from(:member_sessions).
      update(token: Sequel.function(:concat, "ses_", Sequel.function(:gen_random_uuid)))

    alter_table(:member_sessions) do
      set_column_not_null(:token)
    end
  end

  down do
    alter_table(:member_sessions) do
      drop_column :token
      drop_column :logged_out_at
      drop_column :last_access_at
      drop_column :impersonating_id
    end
  end
end
