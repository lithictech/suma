# Anonymized Proxy Vendor Accounts

In some cases, Suma cannot provision a product directly.
Instead, members must use a vendor's own app or system.

An example would be renting a Lyft e-bike,
which is done via deep linking, rather than booking the ride
within the Suma app itself.

In these cases, we have the member sign up with the vendor using
an email or phone number that Suma provisions,
**not** the member's actual email or phone number.

The Suma backend 'proxies' messages from the vendor (email or SMS)
and sends them onto the Suma member (usually SMS).

This keeps member data private on Suma's systems.
Note that other concerns, like liability waivers and vendor complaints against members,
must be worked out beforehand, between the platform operator and the vendor.

We call these 'anonymized proxy vendor accounts', or 'vendor accounts' for short.
In the UI we call them 'private accounts', though this may change.

## User/Data Flow

This is the core data flow around authentication between Suma and a vendor's system:

- We have a 'private accounts' area of the UI with available vendors,
  like Lyft and Lime.
- Members can 'create a private account' for each vendor, or see the email/phone associated with the account.
  - Creating a private account with provision a 'proxy' SMS number for the member,
    and/or assign them an email like `u100@in.mysuma.org`, depending on what the vendor uses for signup.
  - Email is preferred since it's basically free.
- Each vendor in the list has instructions on how to sign up using the member's proxy phone number or email.
- We always listen for incoming emails or SMS. When they come in,
  we see who they were addressed to to look up the member with that proxy address.
- We extract information from the message, and send it via SMS to the member's real number,
  so they member can see it.
  - For example, Lime may send an email with an auth token; we extract the token and send it to the member's phone number,
    like 'Your Lime code is abc123'.
- The member sees an auth token SMS from Suma; copies the token; and pastes it into the vendor's app
  to verify the proxy address.
- Member uses the vendor's app as normal, but the vendor doesn't know who they are directly.

## Architecture

There are two main chunks to how Private Accounts work.
The `Suma::AnonProxy` namespace contains most of this code.

The first chunk are the database models that are surfaced in the UI,
which represent the vendors which support private accounts
(`VendorConfiguration`), the proxy addresses for members (`MemberContact`),
and a member's account within a vendor's service (`VendorAccount`):

- `AnonProxy::MemberContact` contains an email or phone number associated with the member. 
  - Each member can have any number of emails and phone numbers, though one of each is normal.
  - The member contact stores the name of a `Relay`, like Postmark or Twilio.
    This is the underlying provider working with the address,
    and is used when processing inbound messages.
- `AnonProxy::VendorConfiguration` describes the way private accounts
  work for a particular vendor. For example, if Lime uses email for its account,
  there would be a Vendor Configuration associated to that vendor,
  which says that email is used for the private accounts.
- `AnonProxy::VendorAccount` is the member account in the vendor's service.
  It points to a single `VendorConfiguration`, which specifies the behavior,
  and a `MemberContact`, which should match the sms or phone requirement
  (ie, an SMS member contact should be used with a 'uses SMS' vendor configuration).

The second chunk are the mechanics used for the actual proxying;
that is, forwarding messages from vendors to Suma members.
There are a lot more moving parts here:

- We have several `Relay` implementations, like `Postmark` or `Twilio`.
- We use [WebhookDB](https://webhookdb.com) to handle ingestion from external services,
  like Postmark. And our primary method of looking for messages is via database polling.
  This makes ingestion *much* easier to use in non-production environments,
  since we don't need to set up webhooks against local services.
  - In production, WebhookDB pushes changes to our backend so we get immediate alerts,
    and we don't need to depend on frequent database polling.
- There is a recurring `ProcessInboundRelayRows` job that looks for rows in WebhookDB
  for all relays, and 'processes' them.
- Processing includes:
  - Parsing the row using the appropriate `Relay` for the table
    - For example, `Relay::Postmark` processes messages from the `postmark_inbound_messages_v1` WebhookDB replicator.
  - Find the appropriate `MessageHandler` for the parsed message.
    - For example, messages `from: 'no-reply@lime.app'` are processed using `MessageHandler::Lime`.
  - Finding the `VendorAccount` for the given relay, and the recipient of the parsed message.
  - Handling the message using the found handler.
    - This usually includes extracting important info from the message and sending it via SMS.
      In the end a `Message::Delivery` should be created.
    - In some cases, the message may be un-processable, like a Privacy Policy update.
  - This `Message::Delivery` is combined with the `VendorAccount` into a `VendorAccountMessage`.
    This can be used to keep track of all messages processed through a vendor account.
