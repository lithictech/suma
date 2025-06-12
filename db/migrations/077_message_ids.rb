# frozen_string_literal: true

Sequel.migration do
  up do
    from(:message_deliveries).grep(:transport_message_id, "TV-%").update(
      transport_message_id: Sequel.function(:substring, :transport_message_id, 4),
      transport_service: "twilio-verify-sms",
      transport_type: "otp_sms",
    )
  end
  down do
    from(:message_deliveries).where(transport_service: "twilio-verify-sms").update(
      transport_message_id: Sequel.function(:concat, "TV-", :transport_message_id),
      transport_service: "signalwire",
      transport_type: "sms",
    )
  end
end
