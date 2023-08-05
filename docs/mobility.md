# Suma Micromobility System

Suma integrates with many mobility providers,
especially "micromobility" providers for e-bikes and e-scooters.
This document explains that integration.

## Fetching vehicles

The Suma frontend can request all vehicles within a particular bounding box
and for vehicles of a particular type (ebike, escooter, etc).

The vehicles that come back are those that match across all vendors.
The shape of the response is peculiar-
you can see the specs for examples but they look something like this:

```json
{
  "providers": [
    {"name":  "Spin", "slug": "spin"}
  ],
  "precision": 10000000,
  "refresh": 30000,
  "escooter": [
    {"c": [-5000000, 1000000000], "p": 0, "d": "abc123"}
  ]
}
```

There are a few things going on here that bear mentioning,
keeping in mind the "Work With 1 Bar" principle:

- We return all matching vehicles and do clustering client-side.
  The representation is so compact that it is faster
  to request the extra data than have to make requests as the map
  is zoomed in.
- Coordinates are expressed as a latitude/longitude pair `c`.
  We do not use an object to cut down on redundant keys.
- Coordinates are returned as integers.
- The coordinates can be turned back into floats by multiplying `x * (1 / precision)`,
  using the precision returned at the top level.
- The top-level `refresh` field is the number of milliseconds after which
  clients should request new map data for whatever their current bounds are.
  Making this configurable allows the server to be clever about
  potentially serving stale data and asking the client
  for a quick refresh once new data is synced.
- The `p` field corresponds to the index of the vehicle provider
  in the `providers` array. The `providers` array contains enough data
  about the vehicle provider to render its relevant icon.
- If multiple vehicles of the same type have exactly the same coordinate,
  they will have a `d` field. The `d` field is a "disambiguator",
  usually the provider's vehicle id.
- To identify a scooter for getting more info,
  we use a key of `[lat, lng, provider, vehicle type, disambiguator (if needed)]`.
  This avoids returning any long and hard-to-compress string like a vehicle id.

When we fetch the scooter using that key, if it's not present,
we would refresh the available scooters and then it would show up and require the user to
press again, which we think is a reasonable tradeoff.
When inspecting scooter details or trips, we return more full and stable information about the scotter,
including the provider's vehicle id.

## Adding and updating vehicles

We fill our database with vehicles that we fetch from providers,
usually through GBFS feeds but potentially in other ways (like providers who have APIs we can use).

To do this, we fetch vehicle data using provider and eligibility-specific mechanisms,
and replace relevant rows into the `mobility_vehicles` table
(vehicles no longer present get deleted).

This refresh happens on an interval. In the we may be more clever about
how we sync data.

## Starting and ending trips

Interally, we model a 'trip' as a reference to a vendor service, its vendor vehicle id,
and the Suma rate model used to start a trip.
Note the vehicle ID is is **not** a foreign key into the Vehicles table, since that table is transient.
The trip records the time and location of when it was begun and ended.

We abstract communication with vendor backends through the `Suma::Mobility::VendorAdapter` interface
and its implementers.

There are three types of adapters, explained below.
We also have a `FakeAdapter` we use for unit and integration testing.

### Proxying Adapters

**Note**: We do not currently use proxying adapters,
but they are explained here for illustrative purposes.

The first type of adapter is where Suma 'proxies' calls to a vendor,
for example, sending an SMS to start and end a trip.

The complexity around trips comes into play with the external dependency of the mobility services:

- Only start a Suma trip when the service is successful.
- Only end a Suma trip when the service is successful.
- We need to handle orphan trips and unexpected server responses.
- What if the service state, such as the account balance, is not in sync with Suma's balance?
- What happens if we start/end a trip but cannot commit the result to the database?
- Only allow one ongoing trip at a time for all of Suma
  (we could modify this to be per-service in the future since it is technically possible, if not advisable).

We cannot answer all of these questions perfectly,
and will improve our answers as time goes on.

It's important to keep in mind that, though Suma models trips,
they are not authoritative in terms of duration and cost-
the vendor systems themselves are authoritative, especially for cost.

Because of this, though the trip points to a 'rate',
the rate is only used for descriptive purposes. It does *not* calculate the money
that the resident owes; instead its used to predict trip cost and model
the undiscounted cost of the trip.

### Deep-linking Adapters

Some vendors do not support any sort of write-level integration,
so we can't even use proxying.

In these cases, the mobility adapters support 'deep linking,'
which provides a URL for each vehicle.

Deep linking always requires an **Anonymous Proxy Vendor Account** (aka Private Account).
See the documentation on Private Accounts (in `/docs/proxy-accounts.md`) for more information.

We use these Private Accounts to connect the Suma user to the vendor service.

The big challenges here are things like dealing with charges
and historical trip information; we'll fill this out as we have to deal with it.

### Mobility-as-a-Service Adapters

Some mobility vendors support a Mobility-as-a-Service (MaaS) API.
These are the nicest to work with, because you're 'just' using a 'normal' API.
They all have support for things like staring and ending trips,
and we can get rates, ongoing and historical trips, and actual charges from them.

Invoices for trips are also done on some period,
rather than at point-of-service, which also fits our our model best.
