# Payment Triggers

One complex topic Suma handles is automatically providing subsidies (credits)
to members based on certain criteria, in the form of Book Transactions from a Suma platform ledger
to the member's ledger.

We often call these types of payments 'subsidies,' and we'll use the terms interchangeably,
though the 'payment trigger' system can be used to create any type of payment
(that is, the fact that it's a subsidy is a use-case feature, not a platform feature).

These subsidies go beyond simple discounts or coupons- they need to integrate with
the multi-ledger payments system described in `docs/payments.md`.

To do this, we start by fully modelling subsidies,
including match amount per dollar, maximum match,
ledger categories, eligibility constraints, etc.

Then, when we create a funding transaction (and its related book transactions),
we run the subsidy automations/payment triggers.

- Triggers are narrowed down based on constraining criteria.
- Each trigger is run to generate output book transactions.
- Everything is reflected on the ledger.

However! This is the easy case. The complex case is where we need to know
**how much someone will pay before they pay it.**

That is, imagine we have product priced at $20, with a 1-to-1 subsidy up to $5.
We need to know in advance that this will cost the member $15 cash, with $5 subsidy.

However, this needs to spread to multiple products, with multiple ledgers and categories.
Imagine a cart with 3 $10 products: organic local carrots, local kombucha, and organic bananas.
There is a 1-to-0.7 match for organic food up to $7.50,
and another 1-to-0.7 match for local food up to $7.50.

We need to be able to know that we want to add $15 in cash, to get $15 in subsidy.
You can see all the complexities of this, though,
with different product categories and subsidy matches.
Lowering or raising the cash amount can have many follow-on effects,
similar to a [three-body problem](https://en.wikipedia.org/wiki/Three-body_problem).

To solve this, we run a 'simulation' at different cash amounts.
When we find a cash contribution where the cost of the cart is covered,
and $0 is left on the ledger, that is the cash amount we use.

In our $30 example above, we would start at all-cash, and then 'bisect' lower cash amounts.

Note: If you're unfamiliar with bisecting,
it's useful to understand how something like `git bisect` works.

- Use $0 cash. It's possible we can cover the full amount using existing ledger subsidy.
- Use $30 cash (the full cart amount). Find that we have $15 in cash left over
  after trying to pay using the 'ledger contribution' system described in `payments.md`.
- Use $10 cash. Find that our paid total is $10 under ($10 cash plus $5 organic plus $5 local).
  - Note: We'd actually use $15 here (bisect the total cost and $0),
    but since that is correct number, we use $10 for illustration/so we have more bisect steps.
- Use $20 cash. Still has cash left over.
- Use $15 cash. Find that we can cover the $30 total, and have $0 cash left over, meaning that
  this is the optimal amount.

Note that we could end up with extra subsidy in our wallet-
we stop bisecting at a minimum charge amount
(or $0, if the cost is covered fully by subsidy). That's fine though,
extra subsidy on ledgers is okay to carry around and will be factored into future purchases.

One ambiguity is what should be done when someone has an existing cash balance on the ledger.
For example, given the scenario above, but with $10 on the cash ledger,
a member could pay in two ways:

- Maximize the subsidy: Add $15 cash to get $15 subsidy.
  They'd end up with $10 on their cash ledger still.
  They spent more than they had to *today* in order to maximize savings.
- Minimize their cash spend: Add $10 cash to get $10 subsidy.
  They'd end up with $0 on their cash ledger.
  They spent the minimum they had to *today* ($5 less) but left $5 in subsidy on the table.

There is no 'right' answer here. We either need to:

- Restrict the cases where users can have cash on their ledger (by removing the 'Add funds' page).
- Add the ability for users to choose their cash contribution (not implemented yet).

## Implementation

There are a few parts to payments triggers:

- 'Projecting' how much someone will be charged when they check out.
- The triggers themselves, which model what additional transactions
  are created given a funding transaction.
- Simulating to find the correct cash charge which results in enough subsidies being generated.
- Ledger contribution lookups.

The solution here is deceptively simple (at least in terms of changes needed).

To determine the 'projected' amounts:

- For each step of the 'simulation' with the simulated cash amount,
- Run triggers to get the book transaction amounts to be added to ledgers,
- Find the ledger contributions for the products.
- As soon as we find no remainder and no cash contribution required,
  we have the correct simulated cash amount.
- Roll back the transaction, and return the contributions.

Then, when the user submits the checkout:

- Create the cash book transaction for the simulated amount.
- Complete the checkout/create the order.
- Assert there is no remainder to be charged, or cash left on the ledger
  (ie it's possible the state of the ledger has changed between when the user viewed
  the projected charges and submitted the order).
- Create the funding transaction once everything is good.
