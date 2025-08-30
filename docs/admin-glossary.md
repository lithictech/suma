# Admin Glossary

Glossay of terms anyone using the Admin App (reachable at `/admin`) needs to know.

Not all of these may appear in the Admin navigation panel,
some are hidden based on your **Role**.

## Accounts

### Members

We call user accounts **Members** instead of "users" for ideological reasons, but it's the same idea.

Everyone who logs into Suma is a **Member**.

### Organizations

**Organizations** represent groupings of **Members**. This is normally something like an affordable housing provider,
but it can represent any entity where that Suma members can be a member of.

### Organization Memberships

**Organization Memberships** put members into organizations. **Members** can be in multiple **Organizations**.
Their membership must be verified by an administrator or the backend.

## Payments

### Ledgers

**Ledgers** keep track of the different types of funds available for a member,
like a bank account in the outside world.

Each member has multiple ledgers, like people can have multiple bank accounts.

Every member has a 'cash' ledger which can be used for anything;
all other ledgers have funds available that can be used for specific purposes.

In general, when operating with a "charge members at point of service" (checkout, trip completion) model,
all ledgers should have \$0.

In addition to member ledgers, there are also **Platform Ledgers**.
These are basically a reciprocal version of member ledgers, but they belong to the platform itself, not a member.

Note that ledgers also have **Categories**. These categories control what products/services the ledger can be used
to pay for. See **Categories** for more info.

The behavior of the ledgering system is extensive and is not covered here. 

### Charges

**Charges** tie together purchases (like **Orders** and **Trips**) and the charges.
They are not really part of the payment system itself, but rather, a way to tie payments into the commerce system.

**Charges** summarize what was purchased, and how it was paid.
Especially noteworthy is that charges keep track of what money was moved between what ledgers
(**Book Transactions**) as well as any money moved onto the platform to cover the purchase (**Funding Transactions**).

### Book Transactions

**Book Transactions** cover money movement between **Ledgers**.

### Funding Transactions

**Funding Transactions** move money from the outside world into Suma.
For example, every credit card charge has a corresponding **Funding Transaction**.

### Payout Transactions

**Payout Transactions** represent a payout, like a bank transfer or a physical check,
drawn against the Platform's cash reserves. For example, if 10 members pay \$10 for a meal,
(generating \$100 in **Funding Transactions**), and we need to pay our vendor \$9 per meal,
we'd generate a \$90 **Payout Transaction** to the vendor (leaving \$10 in cash on the Platform).

### Payment Triggers

**Payment Triggers** describe **Book Transactions** that are automatically created under certain criteria.
For example, spending \$5 on farmers market vouchers can generate a \$19 **Book Transaction** from a
**Platform Ledger** (representing the subsidy source, and which can only be used for farmers market vouchers)
to the member's ledger.

One important aspect of triggers is that they can be run "hypothetically",
which is how we can show a **Member** what subsidy they are getting for an **Order**.

## Commerce

### Offerings

**Offerings** are timed collections of things being offered for sale.
In particular, they allow certain groups of **Members** (through **Programs**)
to see certain **Products**.

For example, maybe we want every affordable housing user
to see holiday meals, but only residents with one partner to see
an additional holiday meal **Offering**.

Or we want to vary the **Fulfillment Options**.

#### Fulfillment Options

**Fulfillment Options** list the options available for fulfillment at checkout.
This is often something like different addresses available for pickup.

### Products

**Products** are things that can be offered for sale.
This is where images, description, and inventory information is stored.

It's important to note the **Category** for the product,
which is what determines which **Ledgers** can be used to pay for it.
See **Categories** below.

#### Offering Product

**Offering Products** tie a **Product** to an **Offering**, and contains the price being charged in the offering.
*Prices are immutable*. Any change in price creates a new **Offering Product**,
and expires the old one (this is done automatically when changing the price in admin).

### Orders

**Orders** are created when someone places an order.
**Orders** show:

- The **Member** who ordered,
- The items in the order, which point to **Offering Products**,
- The costs and discounts involved, and the **Charge** made.

Orders have an "order status", which is one of:
- _open_: still have work to do,
- _completed_: nothing else to do,
- _canceled_: nothing else to do and the order can be ignored for all purposes.

Orders also have a "fulfillment status", which is one of:
- _unfulfilled_: nothing has been done to fulfill the order, 
- _fulfilling_: the order is being fulfilled (packing, shipping, etc.),
- _fulfilled_: the order has been received by the member (or something equivalent).

Often **Orders** are immediately fulfilled so can go straight from unfulfilled to fulfilled,
like for a member buying vouchers.

### Mobility Trips

**Mobility Trips** are scooter or bike rides or similar. These are synced from external systems
and only limited fields can be manually edited.

## Vendor Management

### Vendors

**Vendors** represent entities on the platform that we are reselling.
These can be a wholesaler (we buy products from them), retailer (grocery store),
service provider (micromobility companies), etc.

### External Accounts

**External Accounts** represent a **Member** in an external **Vendor** system,
like the Lime or Lyft apps/backends.
These are managed automatically so are not editable.

### External Account Configs

**External Account Configs** describe the connection between a **Vendor** and how to manage a member's **External Account** for that **Vendor**.

This includes instructions, but also technical aspects like how to perform authentication with the vendor's system.

### Vendor Services

**Vendor Services** are similar to **Offerings** but for ongoing services vendors provide (like mobility),
rather than transactional events (like orders).

**Vendor Services** also have **Categories**, which control what **Ledgers** can be used to pay for it.

#### Vendor Service Rates

**Vendor Service Rates** describe the expected (or in some cases actual) pricing for the **Vendor Service**. Because the same service can have different rates,
the actual rate a user sees depends on the pricing set up through **Program Pricings**.

## Platform

### Programs

**Programs** represent the programming for the platform's members, and (through **Program Enrollments**)
allows members to access **Offerings** and **Vendor Services**.

The **Programs** a member can access are visible to members on their dashboard.

**Programs** with an "app link" have some action they can take on the platform, like viewing an **Offering**. **Programs** without an app link are informational-only, like informing the member of services available off-platform.

Programs also have a collections of **Pricings**. These pricings associate as **Vendor Service**
(such as "lime scooters"), with a **Vendor Service Rate** (such as "50 cents to unlock, 7 cents a minute). This allows us to know price a member should have for a given vendor service.

### Program Enrollments

**Program Enrollments** allow members access to **Programs**. Enrollments must be approved to be active.

Members can access programs through:

- _Direct enrollment_, where a member is enrolled in the program.
- _Organization enrollments_, where a member can access the program by being a verified member in an organization enrolled in a program.
  For example, "all Housing Provider members can access free e-bike rides."
- _Role enrollments_, where a member can access the program by having a particular role.
  For example, "all beta testers have access to free e-bike rides."

### Messages

**Messages** are all the messages the backend sends, including verification passcodes, order confirmations, etc.

### Static Strings

Static strings are not tied to specific pieces of content, like program
descriptions. They are usually referred to directly in the UI (like form
labels), or their keys are referred to by dynamic content (like how offerings
have a field for their confirmation email template).

Static string editing is a specialized task; if you aren't trained on it, you can still tweak what is there,
but fully working with static strings is outside the scope of this glossary.

## Technical-only

These are not editable in admin.

### Roles

**Roles** are a conceptual grouping of members. Most commonly this is used for "role-based access control" (RBAC),
which is what allows some users to see only some parts of admin.

Since members can have multiple roles, roles can be used for any conceptual grouping.
One could be "mobility beta tester," which would give access to mobility **Programs** that are being beta tested.
These members do not even need to be in any organization.

### Categories

**Categories** are a conceptual grouping of purchasable things (**Products**, **Vendor Services**) on the platform.
**Ledgers** also have categories.

Categories are hierarchical. For example, `Food -> Local Food -> Alan's Farm`.

A Ledger with the category `Alan's Farm`, perhaps funded with a donation from Alan's Farm, can be used
only to pay for products with the category `Alan's Farm`.

A Ledger with the category `Local Food`, perhaps funded by a state funding incentive program,
can be used to pay for products with the category `Alan's Farm` *or* `Local Food` categories.
