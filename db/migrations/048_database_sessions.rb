# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table(:member_sessions) do
      add_column :opaque_id, :text, unique: true
      add_column :logged_out_at, :timestamptz
    end
    from(:member_sessions).
      update(opaque_id: Sequel.function(:concat, "ses_", Sequel.function(:gen_random_uuid)))
    # alter_table(:member_sessions) do
    #   set_column_not_null(:opaque_id)
    # end
  end
  down do
    alter_table(:member_sessions) do
      drop_column :opaque_id
      drop_column :logged_out_at
    end
  end
end
