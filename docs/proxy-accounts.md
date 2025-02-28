# Anonymized Proxy Vendor Accounts

In some cases, Suma cannot provision a product directly.
Instead, members must use a vendor's own app or system.

An example would be renting a Lyft e-bike,
which is done via deep linking, rather than booking the ride
within the Suma app itself.

In these cases, there are two possibilities:

1. We have the member sign up with the vendor using an email or phone number that Suma provisions,
  **not** the member's actual email or phone number. We call these **"Private Accounts"**.
2. We link the member's Suma account and a vendor account with the same email or phone number.
   These do not provide depersonalization/anonymization. We call these **"Linked Accounts"**.

The mechanics of these are very similar, and mostly just changes the UX.
But we can explain them with examples.

## Linked Accounts

Linked accounts are pretty simple. In these cases, Suma has some relationship with the vendor
that allows Suma to enroll its members in some special vendor programs.
An example would be enrolling Suma members in Lyft Pass, giving them a discounted rate for mobility trips.

In these cases, when the user Links their account, we will invite the user with the same email or phone number
to join our Suma account. This will usually do something like:

- User presses 'link account' in the UI.
- Suma backend automation adds the member's phone number to a special discount program with the vendor, like Lyft Pass.
- Lyft automatically sends a notification to the user about the invitation.
- Suma's UI tells the user to look out for a message and open the app.
- Member opens the Lyft app and see their new access.

Note that because we didn't initially plan on non-anonymized accounts,
the code namespace is "anonymous proxy", even though these accounts aren't anonymized,
and are not really proxied.

## Private Accounts

With private accounts, the account in the vendors system is NOT the actual Suma member email or password.
Instead, the Suma backend 'proxies' messages from the vendor (email or SMS)
and sends them onto the Suma member (usually SMS).

This keeps member data private on Suma's systems.
Note that other concerns, like liability waivers and vendor complaints against members,
must be worked out beforehand, between the platform operator and the vendor.

An example of Private Accounts would be associating Suma with Lime:

- The member should not be signed in to Lime.
- The member presses the button to link/open their Lime account.
- Suma makes a request for a 'magic link' signup/sign-in to an email like `m5@in.mysuma.org`
- Suma parses the incoming email and sends the private link to the member via SMS.
- The member clicks on the private link, and is signed in to Lime as `m5@in.mysuma.org`.
- Lime does not know anything about the member.

## Architecture

There are two main chunks to how Private and Linked Accounts work.
The `Suma::AnonProxy` namespace contains most of this code.

The first chunk are the database models that are surfaced in the UI,
which represent the vendors which support private accounts
(`VendorConfiguration`), the proxy addresses for members (`MemberContact`),
and a member's account within a vendor's service (`VendorAccount`):

- `AnonProxy::MemberContact` contains an email or phone number associated with the member. 
  - Each member can have any number of proxy emails and phone numbers,
    though it wouldn't be very useful to have multiple email addresses or phone numbers.
  - The member contact stores the name of a `Relay`, like Postmark or Twilio.
    This is the underlying provider working with the address,
    and is used when processing inbound messages.
- `AnonProxy::VendorConfiguration` describes the way private accounts
  work for a particular vendor. For example, if Lime uses email for its account,
  there would be a Vendor Configuration associated to that vendor,
  which says that email is used for the private accounts.
  The Vendor Configuration also describes how to auth to the vendor,
  whether it's something like an HTTP request to request a magic link,
  or custom code like for Lyft Pass.
- `AnonProxy::VendorAccount` represents the Suma member's account in the vendor's service.
  It points to a single `VendorConfiguration`, which specifies the behavior,
  and a `MemberContact`, which should match the sms or phone requirement
  (ie, an SMS member contact should be used with a 'uses SMS' Vendor Configuration).

The second chunk  of complexity are the mechanics used for the actual proxying;
that is, forwarding messages from vendors to Suma members.
Note these are only needed for Private Accounts, not Linked Accounts.
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
