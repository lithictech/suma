# Suma Vendors, Services, and Payments

The concept of a "vendor" in Suma can be used for a number of things,
such as who is behind a product. Products are part of the "Commerce" system;
see [Commerce](commerce.md) for more information.

This document is specifically for "Vendor Services,"
which are more like the "services" side of the "products vs. services" split.
Specifically, something is a service, and not a product,
if it has a "rate".

One example of this is micromobility device use,
which usually have a surcharge (\$1 to unlock) and per-unit fee (\$0.50/minute).
See [Mobility](mobility.md) for more about mobility specifically.

Note also that including subsidies in vendor services is potentially not possible;
while we can know how much subsidy will be contributed to the purchase of any item,
it isn't clear we can do this for services, which have both an unknown constituency
once purchased (how many minutes?), and usually happen off-platform to boot
(so are up to vendors to price). This could change in the future,
but for now, payment triggers are not used for mobility (subsidies may be handled differently).

## Models

The key models involved are:

- **Vendors** model those companies and individuals that provide **services**
  on the Suma platform.
- **Services** model the unique offerings vendors provide.
  For example, the "Lyft" vendor may have e-bike and rideshare services.
- **Rates** are how much a service costs.
  Rates have a unit cost (unlock fee), per-unit cost (price per minute),
  unit offset (first 30 minutes free), and localization key (how to show the rate to the user).
    - The localization key is what says "<unit cost> per minute" rather than "<unit cost> per hour",
      or however it should be represented. Then each subsystem using rates knows how to interepret
      the unit cost (mobility is always per-minute for example).
    - Rates can also point to an 'undiscounted rate' to calculate savings.
- **Program pricing** links programs, vendor services, and rates
  (making sure we charge members with access to a service the right rate).
- **Charges** are created from rates. They are the high-level member-facing objects
  that describe what a member is charged.

## Service Rates: Showing scooter trip costs

When we show mobility vehicles on the map, they include information about how much they cost
(discounted and undiscounted). This is done through the vendor service rate attached to the vehicle.

Since this doesn't involve the payment system, and we aren't dealing with payment triggers,
this is pretty straightforward.

## Charges and Line Items

Unlike [Commerce](commerce.md), which happens primarily on-platform so is easier to follow,
working with Vendor Services generally happens off-platform,
and thus the integration is a lot more varied and complex.

Each charge should have one or more 'line items'.
Each line item represents some part of the charge,
like an itemized receipt.
The total of the line items is always the total cost of the charge.

Each charge also has one or more 'contributing book transactions'.
These are the book transactions the 'checkout' (order checkout, trip charging)
created in order to pay for the charge.
The total of these transactions would be the amount that came from existing
ledgers or subsidies as part of checkout.

These contributing book transactions can also be thought of like
credits or promos applied to the itemized receipt;
line items are usually positive, and would not represent a subsidy,
like you may see on a receipt; that is what the contributing book transactions do.

Though keep in mind that money off the 'cash' ledger is generally not a subsidy,
it is more like paying with preloaded cash.

The charge may have also created a funding transaction,
to pay for any balance not covered by existing ledgers (or triggers).
This funding transaction usually creates another book transaction,
but it isn't part of the contributing book transactions;
it is what the user paid out of pocket.

### Subsidizing vendor services (Payment Triggers)

For now, vendor service subsidies are handled with a Payment Trigger
that is associated with the same Program being used,
and the relevant Vendor Service Category.

The logic is a bit naive still, but will likely get more sophisticated in the future.
The safest bet is to assign a trigger to a category you know is relevant (`mobility`,
`lime_mobility`, etc.) to a particular mobility program.
Give is a 1-1 match and a zero maximum subsidy.

### Example 1: Lyft Pass, Biketown for All Pricing, Suma Paying Full Cost

For this case, we are fully subsidizing user trips through a Lyft Pass coupon.
Users in this program are low-income so we know they are eligible for Biketown for All low-income pricing,
which is applied automatically through Lyft.

User takes a ride, for which Lyft charges:

- \$0.50 unlock fee
- \$2.10 ride fee (\$0.07/min for 30 minutes)
- \$1 Lock Fee (outside of station)

Suma's Lyft Pass is configured to cover this entire trip cost, so Lyft will invoice Suma \$3.60.

We want this to look like the user took a \$12.50 trip,
which was discounted to \$3.60, Suma contributed a \$3.60 subsidy to,
and cost them \$0 out of pocket.

Suma would set up a Vendor Service Rates:

- Primary: \$0 surcharge, \$0 unit cost
- Undiscounted rate: \$1 surcharge, \$0.35 unit cost

When Suma creates a `Suma::Mobility::Trip` for this Lyft trip (see `Suma::Lyft::Pass`),
we would create the following objects:

- `Charge(undiscounted cost=\$12.50)`, calculated by adding:
    - \$1 surcharge
    - \$10.50 unit cost (\$0.35 * 30 minutes)
    - \$1 Lock Fee (inferred additional cost when parsing receipt)
- 3 `Line Items` adding up to \$3.60:
    - \$0.50 unlock fee, from receipt.
    - \$2.10 ride fee (\$0.07/min for 30 minutes), from receipt.
    - \$1 Lock Fee, from receipt.
- 1 `Book Transaction` for \$3.60 from the Suma platform mobility ledger,
  to the member mobility ledger.
  - Calculated from the 'transaction amount' from Lyft Pass (what Suma paid).
  - This requires setting up a `Payment Trigger`, as above.

### Example 2: Lyft Pass, Biketown for All Pricing, Suma Paying Partial Cost

For this case, we are partially subsidizing user trips through a Lyft Pass coupon.

User takes a ride, for which Lyft charges (same as previous example):

- \$0.50 unlock fee
- \$2.10 ride fee (\$0.07/min for 30 minutes)
- \$1 Lock Fee (outside of station)

Suma's Lyft Pass is configured to cover half of the trip cost, so Lyft will invoice Suma \$1.80
and will charge the user \$1.80.

Suma would set up a Vendor Service Rates:

- Primary: \$0.25 surcharge, \$0.035 unit cost
- Undiscounted: \$1 surcharge, \$0.35 unit cost

When Suma creates a `Suma::Mobility::Trip` for this Lyft trip (see `Suma::Lyft::Pass`),
the Charge (and related objects) created at:

- Charge with an "undiscounted cost" of $12.50,
  calculated using the undiscounted vendor service rate and inference from line items:
    - \$1 surcharge
    - \$10.50 unit cost (\$0.35 * 30 minutes)
    - \$1 Lock Fee (inferred additional cost when parsing receipt)
- Line items adding up to \$1.80:
    - \$0.50 unlock fee
    - \$2.10 ride fee (\$0.07/min for 30 minutes)
    - \$1 Lock Fee (outside of station)
    - -\$1.80 subsidy from the Suma platform mobility ledger (**book transaction line item**),
      calculated from the 'promo' line item cost * -1.
- -\$1.80 off-platform payment to Lyft
- The "cost to you" is \$1.80.
    - "Cost to you" is always a sum of line items, minus off-platform payments.

To the user, this will look like a \$12.50 trip that they paid \$1.80 for.

### Example 3: Lime Report, Lime Access Pricing, Suma Paying No Cost

The main difference between Lime Reports and Lyft Pass is that Lyft charges users directly,
and invoices Suma for the subsidy provided.
With Lime, we are invoiced by Lime for the entire cost, and then charge users as we want.

We also do not get an itemized receipt, which means we need ot depend entirely on vendor service rates.

Suma would set up a Vendor Service Rates:

- Primary: \$0 surcharge, \$0 unit cost
- Undiscounted: \$1 surcharge, \$0.35 unit cost

User takes a ride of 30 minutes, for which Lime charges Suma \$0.
We would create the following Charge and related items:

- Charge with an "undiscounted cost" of \$11.50, calculated using the undiscounted vendor service rate:
    - \$1 surcharge
    - \$10.50 unit cost (\$0.035 * 30 minutes)
- Line items adding up to \$0:
    - \$0 unlock fee, calculated from primary vendor service rate.
    - \$0 unit cost (\$0 * 30 minutes), calculated from primary vendor service rate.
    - The "cost to you" is \$0.
        - "Cost to you" is always a sum of line items, minus off-platform payments.

To the user, this will look like a \$11.50 trip that they paid \$0 for.

### Example 4: Lime Report, Lime Access Pricing, User Paying Partial Cost

The big new thing here is that Suma will charge the user some amount.

Suma would set up a Vendor Service Rates:

- Primary: \$0.50 surcharge, \$0.07 unit cost
- Undiscounted: \$1 surcharge, \$0.35 unit cost

User takes a ride of 30 minutes, for which Lime charges Suma \$2.60.
We would create the following Charge and related items:

- Charge with an "undiscounted cost" of \$11.50, calculated using the undiscounted vendor service rate:
    - \$1 surcharge
    - \$10.50 unit cost (\$0.035 * 30 minutes)
- Line items adding up to \$2.60:
    - \$0.50 unlock fee, calculated from primary vendor service rate.
    - \$2.10 unit cost (\$0.07 * 30 minutes), calculated from the primary vendor service rate.
    - The "cost to you" is \$2.60.
        - "Cost to you" is always a sum of line items, minus off-platform payments.
    - Book transaction for \$2.60 from the member's to suma's ledger, create a balance of -\$2.60.
    - Funding transaction for \$2.60.
        - Once this collects money, a book transaction from suma's to the member's ledger is created,
          restoring the balance to \$0.

To the user, this will look like a \$11.50 trip that they paid \$2.60 for.

### Example 5: Lime Report, Uncategorized Cost/Discount

We must depend almost entirely on our 'primary' vendor service rates
when processing a Lime report.
When the `ACTUAL_COST` doesn't align with what the service rate calculates,
the issue is reported to Sentry to a programmer can investigate.

In the future, we may automatically add adjustments, but for now,
we err on the side of everything having to match.
