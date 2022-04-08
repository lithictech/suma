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

To do this, we fetch vehicle data using provider and market-specific mechanisms,
and replace relevant rows into the `mobility_vehicles` table
(vehicles no longer present get deleted).

This refresh happens on an interval. In the we may be more clever about
how we sync data.
