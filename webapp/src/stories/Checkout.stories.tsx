import TODO from "../components/TODO.tsx";
import { DemoStack } from "./helpers.tsx";
import type { Meta, StoryObj } from "@storybook/preact-vite";

const meta = {
  title: "Styleguide/Checkout",
} satisfies Meta;

export default meta;
type Story = StoryObj<typeof meta>;

export const CartReviews: Story = {
  render: () => (
    <DemoStack>
      <h2>Empty</h2>
      <CartReview />
      <h2>With Items</h2>
      <CartReview />
      <h2>With Sold Out</h2>
    </DemoStack>
  ),
};

export const PaymentReviews: Story = {
  render: () => (
    <DemoStack>
      <h2>No Instrument</h2>
      <CheckoutPaymentReview />
      <h2>Has Instrument</h2>
      <CheckoutPaymentReview />
      <h2>Has Instruments</h2>
      <CheckoutPaymentReview />
    </DemoStack>
  ),
};

export const FulfillmentReviews: Story = {
  render: () => (
    <DemoStack>
      <h2>No Instrument</h2>
      <CheckoutFulfillmentReview />
      <h2>Has Instrument</h2>
      <CheckoutFulfillmentReview />
      <h2>Has Instruments</h2>
      <CheckoutFulfillmentReview />
    </DemoStack>
  ),
};

export const CheckoutChargeTables: Story = {
  render: () => (
    <DemoStack>
      <h2>Full Price</h2>
      <CheckoutChargeTable />
      <h2>Discount</h2>
      <CheckoutChargeTable />
      <h2>One Subsidy</h2>
      <CheckoutChargeTable />
      <h2>Multiple Subsidies</h2>
      <CheckoutChargeTable />
      <h2>Discount And Subsidy</h2>
      <CheckoutChargeTable />
    </DemoStack>
  ),
};

export const CheckoutReviews: Story = {
  render: () => (
    <DemoStack>
      <h2>Checkout Review</h2>
      <CheckoutReview />
    </DemoStack>
  ),
};

export const CheckoutCompleteds: Story = {
  render: () => (
    <DemoStack>
      <h2>Fulfillment Available</h2>
      <CheckoutComplete />
      <h2>Fulfillment Unavailabale</h2>
      <CheckoutComplete />
    </DemoStack>
  ),
};

const CartReview = TODO;
const CheckoutPaymentReview = TODO;
const CheckoutFulfillmentReview = TODO;
const CheckoutReview = TODO;
const CheckoutChargeTable = TODO;
const CheckoutComplete = TODO;
