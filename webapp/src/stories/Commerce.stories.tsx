import OrderDetail from "../components/OrderDetail.tsx";
import OrderList from "../components/OrderList.tsx";
import TODO from "../components/TODO.tsx";
import { DemoStack } from "./helpers.tsx";
import type { Meta, StoryObj } from "@storybook/preact-vite";
import noop from "lodash/noop";

const meta = {
  title: "Styleguide/Commerce",
} satisfies Meta;

export default meta;
type Story = StoryObj<typeof meta>;

export const OrderHistoryList: Story = {
  render: () => (
    <DemoStack>
      <h2>Order List</h2>
      <OrderList orders={orders} loading={false} onNavigate={noop} />
      <h2>Loading</h2>
      <OrderList orders={orders} loading={true} onNavigate={noop} />
      <h2>Empty</h2>
      <OrderList orders={[]} loading={false} onNavigate={noop} />
    </DemoStack>
  ),
};

export const OrderHistoryDetail: Story = {
  render: () => (
    <DemoStack>
      <h2>Read-only</h2>
      <OrderDetail order={claimedOrder} setOrder={noop} />
      <h2>Claimable</h2>
      <TODO />
      <h2>Editable</h2>
      <TODO />
    </DemoStack>
  ),
};

const orders: SimpleOrderHistory[] = [
  {
    id: 4490,
    serial: "4490",
    createdAt: "2026-07-01T18:50:38.243+00:00",
    fulfilledAt: "2026-07-01T18:52:07.573+00:00",
    total: { cents: 200, currency: "USD" },
    image: {
      caption: "Photo of pints of rasberries. ",
      url: "https://app.mysuma.org/api/v1/images/im_d48u169k30yr7zoikwu24zwxu",
    },
    availableForPickupAt: "2026-04-29T07:00:00.000+00:00",
  },
  {
    id: 1193,
    serial: "1193",
    createdAt: "2024-09-27T19:03:38.697+00:00",
    fulfilledAt: null,
    total: { cents: 3000, currency: "USD" },
    image: {
      caption: "Photo of pints of rasberries. ",
      url: "https://app.mysuma.org/api/v1/images/im_d48u169k30yr7zoikwu24zwxu",
    },
    availableForPickupAt: "2024-05-03T22:30:00.000+00:00",
  },
  {
    id: 61,
    serial: "0061",
    createdAt: "2023-06-30T21:55:47.584+00:00",
    fulfilledAt: "2024-08-23T18:52:49.127+00:00",
    total: { cents: 2400, currency: "USD" },
    image: {
      caption: "Photo of pints of rasberries. ",
      url: "https://app.mysuma.org/api/v1/images/im_d48u169k30yr7zoikwu24zwxu",
    },
    availableForPickupAt: "2023-06-01T19:00:00.000+00:00",
  },
];

const claimedOrder: DetailedOrderHistory = {
  id: 4490,
  serial: "4490",
  createdAt: "2026-07-01T18:50:38.243+00:00",
  fulfilledAt: "2026-07-01T18:52:07.573+00:00",
  total: { cents: 200, currency: "USD" },
  image: {
    caption: "Photo of pints of rasberries. ",
    url: "https://app.mysuma.org/api/v1/images/im_d48u169k30yr7zoikwu24zwxu",
  },
  availableForPickupAt: "2026-04-29T07:00:00.000+00:00",
  items: [
    {
      quantity: 1,
      name: "1:1 Market Match ",
      description:
        "Market Match vouchers can be used to buy produce and packaged goods at the St Johns, King, and Lents Farmers Markets. \r\n\r\nYou can buy up to 15 $2 vouchers for $1 each. (Example: If you buy 15 vouchers, your $15 gives you $30 in vouchers to spend at the market.) You cannot use these vouchers for alcohol or hot prepared foods.",
      image: {
        caption: "Photo of pints of rasberries. ",
        url: "https://app.mysuma.org/api/v1/images/im_d48u169k30yr7zoikwu24zwxu",
      },
      customerPrice: { cents: 200, currency: "USD" },
    },
  ],
  offeringId: 59,
  offeringDescription: "Market Match 2026",
  fulfillmentConfirmation: "",
  fulfillmentOption: { id: 75, description: "Lents", address: null },
  fulfillmentOptionsForEditing: [],
  fulfillmentOptionEditable: false,
  orderStatus: "open",
  canClaim: false,
  customerCost: { cents: 200, currency: "USD" },
  undiscountedCost: { cents: 200, currency: "USD" },
  savings: { cents: 0, currency: "USD" },
  handling: { cents: 0, currency: "USD" },
  taxableCost: { cents: 200, currency: "USD" },
  tax: { cents: 0, currency: "USD" },
  fundingTransactions: [
    { amount: { cents: 100, currency: "USD" }, label: "Visa x-6438" },
  ],
};
