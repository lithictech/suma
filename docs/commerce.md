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

At certain intervals, Suma ops fulfills orders. This is mostly manual right now
and isn't fully modeled. More will be written as ops has more experience
and more tooling is built.

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
  It includes default fulfillment information, like a pickup address.
- `OfferingProduct` makes a product available in an `Offering`. This is the "concrete" version
  of the abstract product. The important thing is that it has prices, described earlier.
- `OfferingCart` and `OfferingCartItem` are the products someone has for an offering.
  We do not allow cross-offering purchases, since their fulfillment will be different.
  Each item represents a quantity (note that the item itself does not have a quantity; instead we have multiple rows).
- `Checkout` is a single checkout flow. It ties to a cart, fulfillment, and other contextual information.
- `Order` and `OrderItem` represents a finished checkout. It is analogous to an `OfferingCart` and `OfferingCartItem`
  but is not editable directly.
  - Orders have statuses, based on [Shopify order statuses](https://help.shopify.com/en/manual/orders/order-status)
    but simplified.
  - Orders are linked to a `Charge`, which represents the debit against the member ledger.
  - Orders are linked to a `FulfillmentService`. For example, for local pickup, this is just a `RelatedAddress`.

## Inventory Management

Suma includes a very basic inventory management system to avoid overselling of limited products.

The flow is:

- Orders with a 'fulfilled' fulfillment status count against available inventory.
- Ops modifies the "on hand" amount of a product they have available.
  They are shown the quantity of orders with an 'unfulfilled' status.
- Orders that have inventory management enabled cannot be oversold. Their quantity is checked during the
  'order creation' process to avoid overselling.

The implementation for this looks like:

- When 'on hand' is modified, an `InventoryAdjustment` is created to adjust the current on-hand
  to the input value.
- OrderItems in a 'fulfilled' status subtract from available inventory.
- So, the quantity on hand of product `X` can be thought of as the psuedo-SQL:
```sql
SELECT
    (
        SUM(SELECT count(1) FROM order_items WHERE offering_product.product_id = X AND order.fulfillment_status='fulfilled')
        - SUM(SELECT SUM(quantity) FROM inventory_adjustments WHERE product_id = X)
    ) AS quantity_on_hand
```

**NOTE**: This is a very basic inventory system, but experience has taught that most fulfillment
can be done with very simple systems. If operator needs get more complex,
we can come up with other solutions- but since Suma is not really meant to be an e-commerce system,
we find this unlikely.
