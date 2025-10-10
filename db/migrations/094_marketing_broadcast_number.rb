# frozen_string_literal: true

require "suma/signalwire"

Sequel.migration do
  up do
    alter_table(:marketing_sms_broadcasts) do
      add_column :sending_number, :text, default: "", null: false
      add_constraint(:numeric_phone, Sequel.lit("sending_number ~ '^[0-9]{11,15}$'") | (Sequel[:sending_number] =~ ""))
    end
    from(:marketing_sms_broadcasts).update(sending_number: Suma::Signalwire.marketing_number || "")
  end
  down do
    alter_table(:marketing_sms_broadcasts) do
      drop_column :sending_number
    end
  end
end
