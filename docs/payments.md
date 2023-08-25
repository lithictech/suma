# Suma Payments System

Payment processing with Suma is one of the most complex parts,
since it has some rather unusual requirements.

Make sure you have read the main technical docs first,
as in particular the "Terms" section is important to keep in mind.

## Funds Flows

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

## Ledgers

All of these funds flows can be grouped into 3 buckets:

- Moving funds onto the platform ("Funding Transactions").
  This would include direct member funding and any other movement of funds onto the platform,
  usually via ACH.
- Moving funds off of the platform ("Payout Transactions).
  This sends money to any bank account (usually for vendors),
  or other type of entity like vendor-specific 'points' accounts.
- Moving funds on the platform ("Book Transactions").
  This is "merely" a balance adjustment between parties.
  It also covers the widets range of transactions,
  including: residents funding other residents, all use of Script and CADs,
  making funds from funding transactions available to a resident's ledger, etc.

We model payments by giving every member one or many ledgers;
everyone has a 'cash' ledger, but there may be additional ledgers
for all services or activities that require non-fungible dollars.
An example would be a Suma instance that partners with food vendors
who offer some SNAP-eligible items.
The `food-snap` ledger could only be used to purchase SNAP-eligible items,
whereas the `general` ledger can be used to cover ineligible items
and any remaining balance from the `food-snap` ledger.

Note that this means any single transaction can involve any number of 'source' ledgers
and a single 'target' ledger (in the future we could support many target ledgers,
but it would require us to allocate the 'source' side in a complex way).

Ledgers are conceptually like standard accounting ledgers:
they have a list of debits and credits and a balance can be drived from them
at any point in time.

Additionally, the ledgers are "append only": that is, we do not model
'failures' or 'reversals' by modifying existing entries.
We do it by adding new entries into the ledger.
This is important since there are many payments and types of payments
moving all the time, and having an older payment affect a newer one
would be very difficult to reason about.

## Platform accounts

There are two important accounts operated by the platform.

The first is the 'business operations account.' This is a normal bank account.
It is held at a normal financial institution.
It is not represented on the platform.

More importantly for the payment system is the 'platform account.'
This is the bank account that a payment processor opens and
runs on behalf of the instance operator.
You generally can only use this bank account through the payment processor,
it is not a general purpose business account (i.e. you cannot use it for a check).

The platform account is initially funded with transfers from the business operations account.
Resident and other payments also fund/credit the platform account.
Payments to vendors, etc., are also done through the platform account.

Like all other ledgers, every debit and credit into and out of the platform account
is represented by a transaction.

All money that comes into the Suma platform goes into this platform account.
When a resident funds their ledger for $50 using their own bank account
(as explained below), that creates a Funding Transaction of $50;
the platform ledger is at $50. Once the Funding Transaction settles
(or immediately, if we want to 'loan' funds),
a Book Transaction is made from the platform ledger to the resident's ledger
so it has a $50 balance.

Eventually the resident spends those funds; each purchase is a Book Transaction
'sending' money from the resident to the platform.
Eventually the resident's ledger would have a $0 balance and the platform a $50 balance.
The vendor sends an invoice, we pay it, and we're back at $0 outstanding.

If inflows and outflows are equal (every cent added to the platform is spent),
the platform account ledger has a $0 balance.
It's unlikely we'd ever see a $0 balance however since at any given time,
lots of cash flow is going on.

## Examples

We'll walk through some examples of how the payments system handles scenarios of increasing complexity.

**NOTE**: In these examples, `$` denotes 'hard currency dollars' and `₴` denotes 'scrip dollars'.

### Bank funding only

- Resident 'loads' $50 into Suma via their bank account.
- A Funding Transaction is set up from the resident's ACH account
  into the platform account.
  This transaction secondarily points to the resident's ledger so they can see the status.
- When the Funding Transaction settles (the platform account gets the funds),
  the platform ledger has a balance of $50.
- A Book Transaction is automatically created sending $50 from the platform ledger
  to the resident's `general` ledger (the `general` ledger always receives normal dollars).
  The platform ledger balance is $0 and the resident's ledger balance is $50.
- Resident uses Suma to purchase $45 of food from an online shopping site for a Food Vendor.
- On checkout, the platform debits the resident's ledger $45 using a Book Transaction,
  sending to the platform account.
- The resident's ledger has a $5 balance. The platform's ledger has a $45 balance.
- The Food Vendor invoices Suma $45 at the start of the next month.
  This gets put into the system as an Invoice.
- Suma pays the Invoice using a hand-written check.
  This gets turned into a $45 Payout Transaction sending funds from the platform account to the vendor's ACH. 
  The payout links to the Book Transfers that the invoice includes,
  which is usually all charges for the month.
  The platform ledger has a $0 balance.
  The resident's ledger has a $5 balance.

### Purchasing and using Scrip

- Residents send $50 from their bank account to their ledger, as above.
- Resident uses $20 of their `general` ledger to purchase ₴22 Scrip (at a $1 to ₴1.1 conversion).
  - This creates two transactions. A Book Transaction debiting the resident's `general` ledger $20,
    crediting the platform ledger $20. And a Book Transaction debiting the platform's `pdx-scrip` ledger $22,
    crediting the resident's `pdx-scrip` ledger.
  - If the platform `pdx-scrip` ledger balance cannot cover the debit,
    a Book Transaction is made debiting the platform `general` ledger
    and crediting the platform `pdx-scrip` ledger. This could be for the exact amount in this example,
    but more likely we'll convert in big chunks.
    The platform `general` ledger has a balance of ($20) and the platform `pdx-scrip` ledger has a balance of $22.
  - The resident's `general` ledger has a balance of $30 ($20 was used),
    the resident's `pdx-scrip` ledger has a balance of ₴22,
    the platform's `general` ledger has a balance of $0 (the $20 member `general` ledger dollars paid off the ($20) balance),
    and the platform's `pdx-scrip` ledger has a balance of ₴0 (the ₴22 was transfered to the member's ledger).
- Resident purchases ₴11 of product from a vendor who accepts Scrip.
- On checkout, the platform debits the resident's `pdx-scrip` ledger ₴11 using a Book Transaction,
  crediting the platform `pdx-scrip` ledger.
  The resident's `pdx-scrip` ledger has a balance of ₴11,
  and the platform's `pdx-scrip` ledger has a balance of 11₴.
- The Vendor invoices Suma for $10 (₴1.1 Scrip => $1).
- Suma pays this invoice, as above.
- In general, Suma will not want to convert Scrip back into hard currency,
  since it defeats the purpose of Scrip.
- But in order to convert Scrip back to hard currency,
  the platform can just initiate a Book Transaction debiting the `pdx-scrip` ledger
  and crediting the `general` ledger at the current conversion rate.
  As with all Book Transactions, it's just an accounting tool,
  and it accurately represents the reduced purchasing power of hard currency vs. Scrip.

### Allocating and Using CADs, multi-ledger payments

"HP" is "Housing Provider" and "CAD" is "Client Assistance Dollars".

- HP wants to load $50 of CAD into their account.
  This creates a Funding Transaction just like the Bank Account funding flow,
  except the funds flow into a `cad` ledger rather than the `general` ledger.
  Once the funds settle, the `cad` ledger balance is $50
  and the platform ledger balance is $0.
- The HP allocates $30 in CAD to a resident.
  This a Book Transaction from the HP's `cad` ledger
  to a resident's specified ledger (`general` or something specific).
  The resident's chosen ledger has a balance of $30
  the HP's `cad` ledger has a balance of $20,
  and the platform ledger still has a balance of $0.
- Resident direct funds $100 (as in Bank Funding example), so has a `general` ledger balance of $100.
  The platform ledger balance is still $0.
- Resident purchases $130 of goods.
- On checkout, a Book Transfer is made to the platform account
  using $30 from the `cad` ledger and $100 from the `general` ledger.
  The resident's `cad` ledger has a $0 balance,
  the resident's `general` ledger has a $0 balance,
  the HP's `cad` ledger still has a $20 balance,
  and the platform ledger has a $130 balance.
- The Food Vendor invoices Suma $130 at the start of the next month.
  This gets put into the system as an Invoice and is paid out via a Payout Transaction.
  The HP's `cad` ledger is at $20, other ledgers are at $0.

### Refunds, and calculating total balance of the Suma ledgering system

This example works with Funding Transactions and Payout Transactions.
It demonstrates how the 'total system balance' can be calculated (sum of all the dollars in the system
added via Funding Transactions and subtracted via Payout Transactions),
versus individual ledger balances (which always work out to $0 since BookTransactions just transfer balance).

- Dee loads $50 into their Suma account. This creates:
  - A Funding Transaction for $50. The `FundingTransaction#platform_ledger` field points to the `platform cash` ledger.
  - Balances are as follows:
    - `platform cash` Ledger: $0, no book transactions
    - `dee cash` Ledger: $0, no book transactions
    - Total system: +$50
      - +$50 `FundingTransaction`
  - Funding transaction processing creates a $50 BookTransaction from `platform cash` to `dee cash`,
    and saves it in the `FundingTransaction#originated_book_transaction` field.
  - Balances at this point are:
    - `platform cash` Ledger: -$50
      - -$50 `BookTransaction` originated
    - `dee cash` Ledger: +$50
      - +$50 `BookTransaction` received
    - Total system: Still $50
- Dee uses $50 to purchase food.
  - This creates a "Charge", which is associated with the order but NOT part of the payments system.
    The Charge is not a source of payments system record; it just connects together application concepts
    like mobility trips and orders, to the payments system.
  - A Book Transaction for $50 is created from `dee cash` to `platform cash`.
  - Balances at this point are:
    - `platform cash` Ledger: $0
      - -$50 `BookTransaction` originated (as part of funding process)
      - +$50 `BookTransaction` received (payment for food)
    - `dee cash` Ledger: $0
      - +$50 `BookTransaction` received (as part of funding process)
      - -$50 `BookTransaction` originated (payment for food)
    - Total system: Still $50

At this point, Dee contacts support and explains he only meant to purchase $25 worth of food
and requests a partial refund.

The first is to truly refund the $20 so it goes back to the original payment instrument,
such as refunding a card charge or sending money back to their bank account.
For this option:

- Suma operators initiate a $20 refund in the payment processor, such as Stripe.
  - Eventually we may initiate refunds from suma, but as of this writing, it's easier to initiate it in the processor.
- Suma backend finds the refund via polling or webhooks.
- Backend creates a Payout Transaction for $20.
  There are also two Book Transactions created, moving money to the member ledger (representing the refund)
  and from the member ledger (representing the payout).
  The `PayoutTransaction#platform_ledger` points to the `platform cash` ledger,
  and its `#originated_book_transaction` points to the `dee cash` to `platform cash` transaction.
- Balances at this point are:
  - `platform cash` Ledger: $0
    - -$50 `BookTransaction` originated (as part of funding process)
    - +$50 `BookTransaction` received (payment for food)
    - -$20 `BookTransaction` originated (to represent refund money to user)
    - +$20 `BookTransaction` received (user sent to Suma for refund payout/withdrawl)
  - `dee cash` Ledger: $0
    - +$50 `BookTransaction` received (as part of funding process)
    - -$50 `BookTransaction` originated (payment for food)
    - +$20 `BookTransaction` received (Suma sending money to user to represent refund)
    - -$20 `BookTransaction` originated (user 'withdrawing' money)
  - Total system: $30
    - +$50 `FundingTransaction`
    - -$20 `PayoutTransaction`

Another choice would be providing a 'credit'- money doesn't move back to the original payment instrument,
but instead is available in the member's cash ledger. Note that, if we were to have to refund a non-cash ledger
like a subsidy, this is always the flow we'd use:

- Suma operators create a $20 Book Transaction in admin, from the `platform cash` ledger
  to the `dee cash` ledger.
- Balances at this point are:
  - `platform cash` Ledger: -$20
    - -$50 `BookTransaction` originated (as part of funding process)
    - +$50 `BookTransaction` received (payment for food)
    - -$20 `BookTransaction` originated (to represent refund money to user)
  - `dee cash` Ledger: +$20
    - +$50 `BookTransaction` received (as part of funding process)
    - -$50 `BookTransaction` originated (payment for food)
    - +$20 `BookTransaction` received (Suma sending money to user to represent refund, is available for use)
  - Total system: $50
    - +$50 `FundingTransaction`

From this we can see that a true refund reduces the total system balance as expected,
and ledgers have $0 at the end,
while a 'credit' refund preserves the total system balance,
and results in non-zero ledger balances (that cancel each other out).

### Refunds of loaded cash

Similar to above, but there may be cases where a refund is needed of loaded cash,
that was not used to purchase anything. This should be rare,
as in most cases gift cards are not redeemable for cash.
But it could happen if, say, someone adds more funds than they intend.

In this case, the flow of funds is:

- Dee loads $50 into their Suma account. Same as above, this creates:
  - A Funding Transaction for $50. The `FundingTransaction#platform_ledger` field points to the `platform cash` ledger.
  - Funding transaction processing creates a $50 BookTransaction from `platform cash` to `dee cash`,
    and saves it in the `FundingTransaction#originated_book_transaction` field.
  - Balances at this point are:
    - `platform cash` Ledger: -$50
      - -$50 `BookTransaction` originated
    - `dee cash` Ledger: +$50
      - +$50 `BookTransaction` received
    - Total system: Still $50
- Dee says they meant to load only $5, not $50, and asks to be refunded $45.
  Suma operators can initiate a refund of the $45, but it will not get the 'credit' book transaction.
  - The `PayoutTransaction#platform_ledger` points to the `platform cash` ledger,
    its `#originated_book_transaction` points to the `dee cash` to `platform cash` transaction,
    and no `#credting_book_transaction` is set.
  - Balances at this point are:
  - `platform cash` Ledger: -$5
    - -$50 `BookTransaction` originated (as part of funding process)
    - +$45 `BookTransaction` received (user sent to Suma for refund payout/withdrawl)
  - `dee cash` Ledger: +$5
    - +$50 `BookTransaction` received (as part of funding process)
    - -$45 `BookTransaction` originated (user 'withdrawing' money)
  - Total system: $5
    - +$50 `FundingTransaction`
    - -$45 `PayoutTransaction`


# Implementation

There are three classes of transactions:

- `Suma::Payment::BookTransaction`
- `Suma::Payment::FundingTransaction`
- `Suma::Payment::PayoutTransaction`

Of these, Book is one "species" and Funding and Payout are another.

Book transactions are immediate, since they are just used for moving
money between internal ledgers. They depend on no external state,
so are very simple to reason about.

Funding and Payout transactions are very similar,
except the former is about receiving funds into Suma's operating account
and the latter is about sending funds from Suma's operating account.

We'll call these _external transactions_ collectively.
The design for external transactions is:

- They are implemented with a **state machine** that models their flow of funds.
- The connection to 3rd party payment processors is abstracted behind a "strategy" concept.
  See the base strategy modules like `Suma::Payment::FundingTransaction::Strategy` for more details.
- All unit testing is done with a "fake" strategy; as long as all strategies adhere to the correct interface
  (and are implemented correctly for their internal logic), we can be confident they work.

State machines are a complex topic, outside the scope of this document.
We use the excellent Ruby `state_machines` library
[github.com/state-machines/state_machines](https://github.com/state-machines/state_machines).

"Strategies" are a design pattern perhaps more accurately called an "Adapter", but no matter.
Given a payment instrument, like a bank account or check recipient, and a set of supported processing partners,
we can figure out which strategy should be used to debit/credit the instrument.
In the future, this support will be dynamic (so, for example, bank accounts could not be used if we do not have
an ACH processor available), but for now, it's explicit.

When a transaction is created, we assume it is _valid_.
"Valid" here means the instruments involved in the transaction are verified,
are not deleted, are registered with 3rd parties, etc.
It does not mean the transaction will succeed, just that it can technically run.
We do this ahead of time validation for two reasons:

- To avoid causing transactions to quickly asynchronously fail,
  which is a bad internal and external UX, and
- Because it is always possible an instrument gets deleted or otherwise becomes invalid
  as the transaction processes. By checking these things only ahead of time,
  we do not pretend to have any guarantees about the same validity
  as the transaction processes.
