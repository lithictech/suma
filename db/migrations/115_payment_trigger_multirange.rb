# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table(:payment_triggers) do
      set_column_type :active_during,
                      :tstzmultirange,
                      using: Sequel.lit("tstzmultirange(active_during)")
    end
  end

  down do
    alter_table(:payment_triggers) do
      set_column_type :active_during,
                      :tstzrange,
                      using: Sequel.lit("tstzrange(lower(active_during), upper(active_during), '[)')")
    end
  end
end
