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

**Suma platform**: The web app, backend, etc., ie all the stuff in this repository.

**Suma instance**: An installation of the Suma platform.
Or put more concretely: a database instance the Suma platform connects to.

**Instance operators**: The team who operates the Suma instance.

**Vendor**: An organization offering goods and services on the Suma platform.
Goods and services are always tied to a vendor.
The Vendor may have 0 or more Members;
Vendor Members may be able to administrate the goods and services
and other aspects of the Vendor's engagement on the platform,
or the Instance Operators can do it.

**Housing Partner**: Every Member must be associated with a Housing Partner.
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

Payment processing with Suma is one of the most complex parts,
since it has some rather unusual requirements.

The flow of funds on the platform can be extremely complex:

- Service usage (scooter rides, food purchases) are liabilities against a resident's Suma balance.
- Suma charges residents for accrued service fees (service usage, Suma/platform fees).
- Residents have multiple Suma balances, as some dollars can only be used for certain services.
- Residents can fund their Suma balance through their bank.
- Residents can send other residents funds through their bank, adding to their balance.
- Housing Partners can contribute Client Assistance Dollars to a resident's balance.
  Some of these dollars can only be used for certain services.
- Suma supports one or many scrips. Scrips can be used only for certain vendors/services,
  like Client Assistance Dollars can. Housing partners and vendors can be given scrip
  to award to residents. There is also a transaction for this scrip purchase
  from the platform operator.
- Residents (and other actors on the platform, like vendors) can send other residents script
  just like they can real money.
- Suma has to pay vendors for service. One model is where vendors invoice Suma,
  and Suma pays them as invoices. An example would be a vendor where
  the instance operator has a 'corporate account',
  and all usage by residents gets billed to that account.
- The other way Suma pays vendors is where Suma has a per-resident 'account' with a vendor,
  and the platform automatically keeps this account funded. An example would be a vendor
  that requires you add 'points' to your account to purchase with. In these cases,
  the vendor does not invoice Suma, instead a bank account/credit card associated
  with the platform is added to the resident's ledger.
- Anything involving bank accounts (ACH) takes several days to settle.
  Even if we used credit cards, those can also be disputed.
  So we need to be able to handle reversals.
- All services have an 'undiscounted rate' so we can keep track of savings.
