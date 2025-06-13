# frozen_string_literal: true

Sequel.migration do
  up do
    from(:message_deliveries).grep(:transport_message_id, "TV-%").update(
      transport_message_id: Sequel.function(:substring, :transport_message_id, 4),
      transport_service: "twilio_verify",
      transport_type: "otp_sms",
    )
    alter_table(:message_deliveries) do
      rename_column :transport_service, :carrier_key
    end
  end
  down do
    alter_table(:message_deliveries) do
      rename_column :carrier_key, :transport_service
    end
    from(:message_deliveries).where(transport_service: "twilio_verify").update(
      transport_message_id: Sequel.function(:concat, "TV-", :transport_message_id),
      transport_service: "signalwire",
      transport_type: "sms",
    )
  end
end
