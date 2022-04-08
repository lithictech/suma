# Suma Architecture

Suma is a comprehensive platform, including a web frontend and API backend.
It is designed to be runnable anywhere
by less technical people who want to work in their community
to enrich their local life and economy.

It is also intended to work well in non-ideal environments on both
client and server- that is, poor internet connectivity on the client
and running the server on a mediocre laptop, for limited load.

## Guiding Principles

Driven by the needs of the communities Suma serves,
we analyze all features and implementation with the following principles:

**Trust and Privacy:** We collect as little data as we can,
and share only what is necessary. Because Suma deals with payments,
we still end up collecting quite a bit of info.
However we will not do any client-side tracking,
and we are careful with what 3rd parties we work with on the server,
and what information is passed.

**Minimize Dependencies:** Designing for running many independent Suma instances
means we cannot take hard dependencies on certain providers.
This means that anything involving 3rd parties,
like banking or sending emails, needs to be abstracted behind an interface
so more implementations can be added in the future.

**Limit Sprawl:** The entire stack consists of two Ruby processes
(web and worker), Postgres, and Redis. The frontend is a
static React Progressive Web App, which is served via the backend,
as to avoid having a separate process. It's easy to deploy to Heroku
or similar hosted environments.

**Work With 1 Bar:** The app should be usable with 1 bar of cell coverage.
This means being resource and asset light,
being diligent with HTTP requests and response payloads,
and resilient against connectivity failures.

**Work on Anything:** The client should run in any modern JS-enabled browser
on a mobile device released in the last 4 years. The server should run
in many hosting environments, and on most laptops,
via Docker or with a system install.

## Terms

**Members**: Members are something analogous to 'customers.'
But everyone on the platform (vendors and housing partners) are also members,
and/or made up of members.
The word 'member' is usually interchangeable with 'resident',
you'll see both used.

**Suma platform**: The web app, backend, etc., ie all the stuff in this repository.

**Suma instance**: An installation of the Suma platform.
Or put more concretely: a database instance the Suma platform connects to.

**Instance operators**: The team who operates the Suma instance.

**The platform**: Usually refers to the automated behavior of the backend
("the platform creates an Invoice") or the external accounts run by Instance Operators
("the platform bank account").

**Platform Ledger and Platform Account**: Collectively referring to the account
that the instance operators operate, through which all funds go onto and leave the platform.
See "Platform Account" below.

**Vendor**: An organization offering goods and services on the Suma platform.
Goods and services are always tied to a vendor.
The Vendor may have 0 or more Members;
Vendor Members may be able to administrate the goods and services
and other aspects of the Vendor's engagement on the platform,
or the Instance Operators can do it.

**Housing Partner (HP)**: Every Member must be associated with a Housing Partner.
The HP determines what discounts and goods and services are available
to its Members. One example would be an affordable housing Community Development Corporation,
which a Member would need to live at to be eligible for Suma.
Another would be the 'catch all HP', for example if someone were running a Suma instance
just for their block, and everyone eligible would be put into the same HP,
and approved just at the whim of the Instance Operators.

**Scrip**: Cash that exists only on the Suma Platform.
This is usually something like a 'local currency',
where vendors agree to take that currency at a discount
in order to keep economic activity local.
Scrip is created using some conversion from normal dollars;
that is, using _n_ dollars produces _t_ scrip,
for any values of _n_ and _t_ >= 0.

**Client Assistance Dollars (CADs)**: Affordable housing partners usually have a discretionary budget
they can allocate to residents. Unlike Scrip, CADs are 1-to-1 with dollars and represent real money.
HPs can award CADs to members through Suma, but Suma has to collect this as a normal payment
from the affordable housing partner.

**Ledger**: Ordered collection of debits and credits.
Every member has a `general` ledger,
and may have additional ledgers for specific types of funds
(SNAP, CADs, etc).

**Transaction**: Any movement of money on the Suma platform.
Involves moving funds onto and off of the platform,
and between ledgers.

**Funding Transaction**: Moving money onto the platform,
like when a resident adds money via ACH.

**Book Transaction**: Moving money between ledgers on the platform.
Never involves transfering actual funds.

**Payout Transaction**: Moving money off the platform,
like for paying vendors, usually from the platform account.

**Invoice**: Represents someone's request for payment.
Transactions can be created from invoices,
but invoices themselves do not involve moving any funds.

## Technical Architecture

Suma looks like a normal Ruby web app with a React frontend.
We should expand on this section in the future,
but it has the normal parts like an API layer using Grape, model layer using an ORM,
workers using Sidekiq, etc.

## Residency Verification

When a resident signs up for Suma, we need to identify if they qualify for the services
and discounts this Suma instance offers. This can be based on whatever criteria
the Suma instance operators decide; but mostly commonly it would be something like
if they are a resident with one of the operator's affordable housing partners.

While a resident is pending verification, or if they have been denied,
they can browse the app, but most features are not available for use.

## Payments System

See the documentation for [Payment System](payments.md).

## Mobility System

See the documentation for [Mobility](mobility.md).