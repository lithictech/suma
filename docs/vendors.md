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
except the presentation is different.

## Models

The key models involved are:

- **Tags** are key/value pairs that can be associated with certain objects,
  most notably residents and organizations.
- **Organizations** model any group of platform users that need
  shared access to a resource. We use organizations to model vendors,
  but also housing partners, funders, and any other group that requires
  identification and access control.
- **Markets** model the name and geography of Suma markets.
  Markets can overlap, and a single-market Suma instance would have a single market
  that covers the whole world. But most Suma instances will involve negotiating
  discounts for specific organizations or groups of organizations.
- **Vendors** model those companies and individuals that provide **services**
  on the Suma platform. One organization can be responsible for several vendors.
- **Services** model the unique offerings vendors provide.
  For example, the "Lyft" organization may have a single "Lyft" vendor
  which has e-bike and rideshare services.
- **Service constraints** describe who can access a service.
  There are several specific types of service constraints:
  - 'market' constraints require the resident's market to be one of the associated markets.
  - 'organization' constraints require the resident to be a member of one of the associated organizations.
  - 'role' constaints require the resident to have the associated role.
  - 'admin' is a 'role' constraint but the role named 'admin'.
  - 'all' constraint allows access from anyone, unless there are other constraints applied.
  For a request to satisfy service constraints, *all* provided values
  must pass their constraint checks.
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

We are not going to worry about multiple markets, vendors, or services here,
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
org = Suma::Organization.create(name: 'Spin')
vendor = Suma::Vendor.create(name: 'Spin', organization: org)
flat_discount_service = vendor.add_service(external_name: 'Spin eScooters', internal_name: 'Spin, Flat Discount')
free_ride_service = vendor.add_service(external_name: 'Spin eScooters', internal_name: 'Spin, 3 Free Rides')
flat_discount_service.add_market_constraint(market: Suma::Market[key: 'pdx'])
flat_discount_service.add_role_constraint(role: Suma::Role.find_or_create(name: 'suma_friends'))
free_ride_service.add_role_constraint(role: Suma::Role.find_or_create(name: 'suma_staff'))
free_ride_service.add_role_constraint(role: Suma::Role.find_or_create(name: 'suma_friends'))
free_ride_service.add_organization_constraint(organization: Suma::Organization[name: 'Hacidenda CDC'])

# Would match free_ride_service since it matches the given constraints
Suma::Vendor::Service.dataset.satisfying_constraints(
  roles: [suma_staff]
)
# Would match no services since it asks for an organization not present
Suma::Vendor::Service.dataset.satisfying_constraints(
  organizations: Suma::Organization[name: 'Verde']
)
```
