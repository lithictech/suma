# Customer Support and Marketing

Suma is built with enhanced support to use [Front](https://front.com) for customer support and marketing.
It is possible to not use Front, and manage support and marketing manually,
but if you use Front you will get better features, including:

- Automatic updating of Front Contacts based on Suma members
- Automatic managing of a Front marketing List (subscribe/unsubscribe users)

## Configuration

Set `FRONTAPP_AUTH_TOKEN` to your team's auth token.

See `Suma::Frontapp` for more configuration options.

## Automatic Contact updating

Whenever a `Suma::Member` is created or updated, we create or update the Front Contact.
See `Suma::Async::FrontappUpsertContact` for more info.

## Automatic marketing List management

**NOTE: Using Front for marketing requires the use of custom channels. You MUST NOT send marketing messages
directly through Front's email system.**

Instead, you can hook up a [Front Channel like WebhookDB/Signalwire](https://docs.webhookdb.com/guides/front-channel-signalwire/)
to send messages you compose in Front through Signalwire, and update SMS replies into Front messages.
Ultimately how you send and sync messages is outside the scope of this document,
but just don't use the default Front channel to do it.

Whenever fields on `Suma::Message::Preferences` are modified, Suma will update the lists the member's Front Contact is on.

## Updating Suma Preferences from Email/SMS

The last part of this is automatically updating a member's message preferences from external actions,
like an email with 'Unsubscribe' or a "STOP" text.

Here are the ways to keep preferences updated:

### SMS via Signalwire and WebhookDB

This requires a [Signalwire Messaging WebhookDB Integration](https://docs.webhookdb.com/integrations/signalwire_message_v1/).

- Set `SIGNALWIRE_MARKETING_NUMBER` and `WEBHOOKDB_SIGNALWIRE_MESSAGES_TABLE`.
- Whenever a text with a STOP keyword (`SIGNALWIRE_MESSAGE_MARKETING_SMS_UNSUBSCRIBE_KEYWORDS`) is received, opt-out is set.
- Whenever a text with a START keyword (`SIGNALWIRE_MESSAGE_MARKETING_SMS_RESUBSCRIBE_KEYWORDS`) is received, opt-in is set.
- Whenenever a text with a HELP keyword (`SIGNALWIRE_MESSAGE_MARKETING_SMS_HELP_KEYWORDS`) is received, no action is taken.
  Instead, the Front channel will see the inbound message and create a Front conversation,
  which should be handled by a support agent.

