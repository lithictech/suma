# Anonymized Vendor Proxy Accounts

In some cases, Suma cannot provision a product directly.
Instead, members must use a vendor's own app or system.

An example would be renting a Lyft e-bike,
which is done via deep linking, rather than booking the ride
within the Suma app itself.

In these cases, we have the member sign up with the vendor using
an email or phone number that Suma provisions,
**not** the member's actual email or phone number.

This keeps their data private on Suma's systems
(other concerns, like liability waivers and vendor complaints against members,
must be worked out beforehand).

We call these 'anonymized vendor proxy accounts', or just 'proxy accounts' for short.

In the UI, we use a simpler terminology of 'private account',
but this may change in the future.

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
- Member uses the vendor's app.

### Caveats

However there are a number of wrinkles, and the devil is definitely in the details.

## Architecture

The areas of code involved in this flow includes:

- The `Suma::AnonProxy` namespace contains most of this code.
- `AnonProxy::MemberContact` is the provisioning of an email or SMS number
  for a member. Each member can have any number of emails and phone numbers,
  though one of each is normal.
- `AnonProxy::VendorConfiguration` specifies the behavior of the vendor account.
  For example, if it uses a phone number or email. It also points to a 'logic adapter'
  which contains vendor-specific code, like how to parse emails or SMS.
  - For now, we assume a vendor account uses a phone or an email.
    Even if both are supported, as assume just one is required.
    We could support both in the same account in the future, but it isn't worth the modeling complexity
    as of this writing.
- `AnonProxy::VendorAccount` is the member account in the vendor's service.
  It points to a single `VendorConfiguration`, which specifies the behavior.
  It also points to a `MemberContact`, which should match the sms or phone requirement
  (ie, an SMS member contact should be used with a 'uses SMS' vendor configuration).
