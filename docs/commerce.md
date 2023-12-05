# Suma Commerce System

Suma provides an e-commerce system that supports the basic actions
that members and vendors need to take.

One useful thing to keep in mind here is that Suma
is not a "platform", like Shopify; it is a "merchant", like a business using Shopify.
So the e-commerce here is modeled where Suma is always on the merchant side;
there is no ability to "check out" via a commerce partner.

In order to list products, the backend automatically or manually must be synced
to the vendor products. Two examples would be:

- Suma does a wholesale purchase from a vendor. It then lists those products,
  and takes responsibility for inventory and fulfillment.
- Suma integrates with a vendor's systems. It can dynamically pull products
  and inventory and update them in the Suma backend. Checkout involves
  placing a Curbside Pickup order in the vendor's system.

Note that as with all goods and services on the platform,
the Suma operator is operating as a retailer
and takes responsibility for all vendor purchases (that is,
the operator is a retailer, not a payment processor moving money
from the member to the merchant).

## Flows

To understand how this all works, we can think of three flows
that combine into the main e-commerce flow:

- Ops lists products
- Members shop
- Ops fulfills orders

## Ops Listing Flow

- Using automated or manual means, Suma Ops has to list products.
  The automated flow is TBD for now.
- Ops creates vendors, representing the supplier, farmer, etc.,
  for the product, however we want to present it.
- Ops creates products, with photos, names, descriptions etc.
  - NOTE: We do not yet support "variants". 1/2 gallon vs. 1 gallon of milk, for example,
    are treated as different products.
- Ops creates offerings, which have a time window and some other data (name, etc).
- Ops adds products to an offering. This includes setting the 'retail', 'discount', and 'wholesale' prices.
  - Wholesale price is what Suma pays the vendor. It is not shown to members.
  - Discount price is what the member pays, if it is set.
  - Retail price is what the member pays if there is no discount;
    if both are set, it represents the discount the member is receiving.
- Ops can change the price for an "offering product", which "closes" the old one
  and starts a new one at the new price.

## Member Shopping Flow

The flow for commerce is:

- Members can see various "offerings" on their dashboard.
  An "offering" is an abstract concept that just groups some set of products.
- Members can 'shop' from products in the offering (add items to their cart).
- Members go to check out with their cart.
- During the checkout flow, members can add a new payment instrument.
  They are required to add to their account balance if it
  does not cover the total.
- Members choose their 'fulfillment'. By default only 'local pickup'
  is available at the location defined on the offering.
- Members finish checkout and an 'order' is created.

## Ops Fulfillment

Each offering may have a time when fulfillment can begin.
At this time, an automated process marks orders as 'fulfilling'.

Offerings that are not 'timed' must have their orders processed manually.

The actually fulfillment of the order is done in the real world.
Once the order is fulfilled, it would get a fulfillment status of 'fulfilled'.

## Models

Because Suma is not meant to be an extensive e-commerce platform or product,
we focus on keeping e-commerce simple. There are models and concepts
that are missing here that may be expected in more robust e-commerce systems,
such as tags for vendors, categories for products, etc.
These *may* be added in the future, but for now, we expect most offerings
to be of a limited scope, rather than for hundreds of SKUs,
so are keeping it very simple (but in a way that is able to evolve in the future).
 
- `Vendor` represents a vendor of goods and services, like "Alan's Farm".
- `Product` represents an abstract product, like "20lb Turkey". It is tied to a vendor.
- `Offering` represents a thing like "Suma Holiday 2022 Extravaganza" (a one-time event with multiple vendors)
  or could be "Food from Alan's Farm" (an ongoing offering with products just from Alan's Farm).
- `OfferingProduct` makes a product available in an `Offering`. This is the "concrete" version
  of the abstract product. The important thing is that it has prices, described earlier.
- `OfferingFulfillmentOption` list the ways an offering can be fulfilled.
  During checkout, a member selects a fulfillment option for their order.
- `Cart` and `CartItem` are the products someone has for an offering.
  - We do not allow cross-offering purchases, since their fulfillment will be different.
  - The `CartItem` points to a product (not an offering product). This causes price changes to products to cause price changes of items in the cart, but NOT during checkout flow, as per `CheckoutItem` below.
- `Checkout` is a single checkout flow. It ties to a cart, payment, fulfillment, and other contextual information.
- `CheckoutItem` attaches a checkout to a specific offering product; this ensures that,
  if the 'active' offering product changes, the checkout does not suddenly point to a new price.
  - **NOTE**: checkout items at first point to a cart item; so if the cart item changes,
    the quantity of the checkout item changes. Once the checkout is deleted or completed,
    however, the `CartItem.quantity` gets copied over to the `CheckoutItem.immutable_quantity`.
- `Order` represents a finished checkout. It has a collection of `CheckoutItem`
  (note that checkout items and their associated offering products are effectively immutable at this point).
  - Orders have statuses, based on [Shopify order statuses](https://help.shopify.com/en/manual/orders/order-status)
    but simplified.
  - Orders are linked to a `Charge`, which represents the debit against the member ledger.
  - Orders are linked to a `FulfillmentService`. For example, for local pickup, this is just a `RelatedAddress`.

## Inventory Management

Suma includes a very rudimentary inventory management system to avoid overselling of limited products.
There is more rationale about this system explained below.

- Products with limited quantity are marked `limited_quantity`.
  This will prevent them from being 'oversold'.
- The amount of a product available is set in the `quantity_on_hand` field.
  This is set by operations when a product is listed,
  inventory arrives, an offering is fulfilled, etc.
- Products have a `quantity_pending_fulfillment` field.
  This is set by the checkout process- when a checkout is completed,
  it is incremented for the purchased quantity.
- When an order is marked 'fulfilled', the quantity of product in the order
  is subtracted from `quantity_pending_fulfillment` and `quantity_on_hand`.
- When an order is checked out, the products are locked.
  Any product where `quantity_on_hand - quantity_pending_fulfillment < quantity being purchased`
  causes an error to be returned due to insufficient quantity.
- When offering products are listed, we look at the `quantity_on_hand - quantity_pending_fulfillment`
  to determine the quantity available for purchase, in addition to the 'max quantity per order'
  and 'max quantity per offering' fields.

**Designer's Note**: This is a very basic inventory system, especially because it denormalizes
significant amounts of data into the inventory system.
However, my experience is that, at this point, it's better to keep this system
very simple in behavior and with known caveats
(like canceling or returning an order results in incorrect inventory),
than it is to develop a more automated, robust inventory system.

It is possible, and ultimately desirable,
to develop a more sophisticated inventory system (with things like an immutable
inventory ledger, projected scheduling, etc), but it is a serious investment.
At this stage, then, a rudimentary system, closer to pen-and-paper,
will be more appreciated by Operations than something more complex and automated
but containing bugs or design issues.

## Limits of Quantity

The maximum quantity someone can purchase has a number of factors:

- On the frontend, we limit the options to a certain number (15 or so).
  Eventually this can/should be replaced but it's rare to purchase more
  than 15 of anything.
- The inventory system, described above, does not allow a product with limited quantity
  to be oversold.
- The product inventory also specifies how many can be sold within a given offering to a specific customer.
  - For example, a product may be an 'introductory offer' that we only want
    a customer to be able to purchase once within an offering. 
  - In theory this should be a feature of an offering product, but that's too much modeling for now
    (because inventory products are immutable, we'd need another object). We can add support for this
    when we have products that need different constraints across offerings.
- The offering specifies how many items a single customer can order.
  For example, a 'flash sale' offering may only want to allow a customer to purchase a single item.
- The offering specifies how many items all customers can order cumulatively.
  For example, we may be doing a bulk purchase but do not want to exceed a certain quantity.

One real-world scenario is offering Farmers Market vouchers:
one 'introductory' product can only be ordered once per-customer, up to 100 for the reason.
The normal vouchers can be purchased anytime.

- The introductory product has a `max_quantity_per_member = 1`.
  - The introductory product is sold out after ordering, other products are available.
- The offering `max_ordered_items_cumulative = 100`.
  - Ensure we don't over-commit introductory products.
- The normal vouchers have no inventory constraints.

Another real-world scenario are holiday meal buys:
reserving a bulk buy for 100 orders, selling about 80 orders, placing the order, and selling the remaining meals.

- The offering has `max_ordered_items_cumulative = 100` and `max_ordered_items_per_member = 1`.
  - Everything appears sold out after ordering one product.
- We place with the vendor an order of 60 of Meal 1 and 40 of Meal 2.
- We update the products to `limited_quantity = true` and set the `quantity_on_hand` to 60 and 40.
- Proper constraints will now be automatically applied.
