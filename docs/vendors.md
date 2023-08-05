# Suma Vendors, Services, and Payments

The concept of "vendors" and "services" are what bridges
the concepts of [Mobility](mobility.md) (and other services)
to [Payments](payments.md).

The roughest analog would be something like an e-commerce store,
and in fact for some vendors, the services look very similar to e-commerce.
Ultimately Suma models a way for residents/members to view
and purchase products, and pay for them;
it so happens that the viewing can be through a map view (mobility services)
or 'shopping view' (some food services), and that the payment
is done through platform currency (similar to gift cards)
rather than represented with a specific charge.

## Example 1: Mobility

When a resident views their mobility map, we need to present available vehicles
they can use. There are many things that can impact what vehicles are available:

- What vendor services serve this geography?
- Are those services restricted to certain attributes the resident does or does not have
  (ie income-restricted)?
- A single vehicle can be offered by multiple services (for the same vendor).
  Which one do we get the vehicles for?

## Example 2: Shopping

When a resident wants to shop (for food, etc), we need to present available vendors
they can shop with. This ends up being conceptually the same as mobility,
except the presentation is different. Specifically, instead of a map with vehicles,
we present a series of offerings a member can shop from.

## Models

The key models involved are:

- **Vendors** model those companies and individuals that provide **services**
  on the Suma platform.
- **Services** model the unique offerings vendors provide.
  For example, the "Lyft" vendor may have e-bike and rideshare services.
- **Constraints** describe who can access a service.
  The constraint system is still being fleshed out,
  but see `Suma::Eligibility::Constraint` for more details.
- **Rates** are how much a service costs.
  This can be something like "one-time charge of amount x",
  or "first 5 charges on a calendar day are free and subsequent charges use the associated rate",
  or "amount x to start and interval_rate for each interval_seconds" after.
  Since we must model some pretty weird rates,
  we end up with some pretty weird 'rate strategies' for particular vendors,
  and very many of them.
  Rates also point to an 'undiscounted rate' so we can calculate savings
  (note the undiscounted rate can be entirely different in calculation
  from the discounted one).
- **Charges** are created from rates. The charge is the resident-facing
  representation of debits in the payment system; the resident-facing
  representation of credits are 'funding transactions' and are generally
  outside of purchasing. Creating a charge creates the necessary payment system objects.

## Concrete Walkthrough: Subsidized Spin Rides

We'll run through an example using Spin scooters
since they have been a partner with mysuma.org in the past.
The example here uses costs for illustrative purposes only.

We are not going to worry about multiple vendors or services here,
since those are the easiest to reason about.

Spin offers e-scooters with two levels of discount
off their undiscounted rate of $1 to unlock and $0.20 per minute.

- $0.50 to unlock and $0.10 per minute to ride.
- First 3 rides a day up to 30 minutes are free ($0.20/minute for overages),
  and then $1 to unlock and $0.20 per minute.

The first discount is available for all Suma residents;
the second discount is available only for low-income residents
and Suma ambassadors.

We'd create something like the following:

```rb
vendor = Suma::Vendor.create(name: 'Spin')
flat_discount_service = vendor.add_service(external_name: 'Spin eScooters', internal_name: 'Spin, Flat Discount')
free_ride_service = vendor.add_service(external_name: 'Spin eScooters', internal_name: 'Spin, 3 Free Rides')
# TODO: example code for subsidized pricing plan
```
