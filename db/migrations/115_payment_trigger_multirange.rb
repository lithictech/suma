# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table(:payment_triggers) do
      set_column_type :active_during,
                      :tstzmultirange,
                      using: Sequel.lit("tstzmultirange(active_during)")
    end
    alter_table(:payment_trigger_executions) do
      add_column :apply_execution_at, :timestamptz
    end
    from(:payment_trigger_executions).update(apply_execution_at: :created_at)
    alter_table(:payment_trigger_executions) do
      set_column_not_null :apply_execution_at
    end
  end

  down do
    alter_table(:payment_trigger_executions) do
      drop_column :apply_execution_at
    end
    alter_table(:payment_triggers) do
      set_column_type :active_during,
                      :tstzrange,
                      using: Sequel.lit("tstzrange(lower(active_during), upper(active_during), '[)')")
    end
  end
end
