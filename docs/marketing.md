# Suma Marketing Support

Suma has some basic tooling for bulk-sending SMS through Signalwire.
This is necessary so that we can send all messages through our own Signalwire number,
which allows them to be hooked up into Front using the [WebhookDB/Signalwire Front Channel](https://docs.webhookdb.com/guides/front-channel-signalwire/).

Members can reply to marketing messages, and it will automatically become part of Front coversations.

## Models

Modeling for the `Suma::Marketing` namespace is relatively straightforward for a marketing domain:

- *Broadcasts* represent the messages being sent.
  They are localized, and the correct message body is automatically sent to the member's preferred language.
- *Lists* can be used to send a broadcast to many recipients.
- *Dispatches* keep track of the messages being sent to recipients,
  and links the broadcasts back to Signalwire messages.

When the broadcast is sent, a background job dispatches SMS through Signalwire.

The WebhookDB/Signalwire Front Channel will automatically sync these 'outbound' messages into Front.
