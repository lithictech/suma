# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table(:message_deliveries) do
      add_column :sensitive, :boolean, default: false, null: false
    end
    from(:message_deliveries).
      where(template: "verification").
      update(sensitive: true)
  end

  down do
    alter_table(:message_deliveries) do
      drop_column :sensitive
    end
  end
end
