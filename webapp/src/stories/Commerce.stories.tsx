import OrderDetail from "../components/OrderDetail.tsx";
import Drawer from "../components/mobilitymap/Drawer.tsx";
import DrawerContentsLoading from "../components/mobilitymap/DrawerContentsLoading.tsx";
import DrawerContentsOngoingTrip from "../components/mobilitymap/DrawerContentsOngoingTrip.tsx";
import DrawerContentsPageError from "../components/mobilitymap/DrawerContentsPageError.tsx";
import DrawerContentsPostTrip from "../components/mobilitymap/DrawerContentsPostTrip.tsx";
import DrawerContentsPreTrip from "../components/mobilitymap/DrawerContentsPreTrip.tsx";
import DrawerContentsVehicleError from "../components/mobilitymap/DrawerContentsVehicleError.tsx";
import MapWithDrawer from "../components/mobilitymap/MapWithDrawer.tsx";
import Chip from "../ui/Chip.tsx";
import Stack from "../ui/Stack.tsx";
import { DemoStack } from "./helpers.tsx";
import mapBackgroundPng from "./map-background.png";
import type { Meta, StoryObj } from "@storybook/preact-vite";
import noop from "lodash/noop";

const meta = {
  title: "Styleguide/Commerce",
} satisfies Meta;

export default meta;
type Story = StoryObj<typeof meta>;

export const OrderHistoryList: Story = {
  render: () => (
    <Stack gap={2}>
      <Chip variant="secondary">Available now</Chip>
      <Chip variant="info">Ready for pickup</Chip>
      <Chip variant="danger">2 left</Chip>
      <Chip variant="success">Picked up</Chip>
    </Stack>
  ),
};

export const OrderHistoryDetail: Story = {
  render: () => (
    <DemoStack>
      <h2>Read-only</h2>
      <OrderDetail order={detailedOrder} setOrder={noop} />
      <h2>Claimable</h2>
      <h2>Editable</h2>
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
      caption: "",
      url: "https://app.mysuma.org/api/v1/images/im_dt8hbx5p5hdv047smnigxry80",
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
      caption: "",
      url: "https://app.mysuma.org/api/v1/images/im_4hrmbxlfg5wyhjcupvwawsg94",
    },
    availableForPickupAt: "2023-06-01T19:00:00.000+00:00",
  },
];

const detailedOrder: DetailedOrderHistory = {
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
