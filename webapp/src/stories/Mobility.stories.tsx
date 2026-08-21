import Drawer from "../components/mobilitymap/Drawer.tsx";
import PostTrip from "../components/mobilitymap/PostTrip.tsx";
import PreTrip from "../components/mobilitymap/PreTrip.tsx";
import Trip from "../components/mobilitymap/Trip.tsx";
import { DemoStack } from "./helpers.tsx";
import type { Meta, StoryObj } from "@storybook/preact-vite";
import noop from "lodash/noop";

const meta = {
  title: "Styleguide/Mobility",
} satisfies Meta;

export default meta;
type Story = StoryObj<typeof meta>;

const vendorService = {
  id: 2,
  name: "Bikeshare",
  slug: "bikeshare",
  vendorName: "Bikeshare Operator",
  vendorSlug: "bikeop",
};

const vehicle = {
  precision: 1,
  vendorService,
  vehicleId: "vehicle1",
  loc: [40, 120],
  rate: {
    id: 50,
    surcharge: { cents: 100, currency: "USD" },
    unitAmount: { cents: 20, currency: "USD" },
    name: "demo",
  } as Rate,
  subsidyMatchPercentage: 20,
  deeplink: "#deeplink",
  gotoPrivateAccount: "#private-accounts",
  usageProhibitedReason: "prohibited",
};

const trip = {
  id: 1,
  vehicleId: 2,
  vehicleType: "ebike",
  provider: vendorService,
  beginLat: 0,
  beginLng: 1,
  beginAddress: { part1: "123 Main St", part2: "Portland, OR" },
  beganAt: "2020-01-01T12:00:00Z",
  endLat: 10,
  endLng: 11,
  endAddress: { part1: "123 Main St", part2: "Portland, OR" },
  endedAt: "2020-01-01T12:00:00Z",
  ongoing: false,
  charge: {
    undiscountedCost: { cents: 200, currency: "USD" },
    customerCost: { cents: 200, currency: "USD" },
    savings: { cents: 200, currency: "USD" },
    lineItems: [{ amount: { cents: 100, currency: "USD" }, memo: "Unlock" }],
  },
  minutes: 20,
  image: null as Image,
};

export const TripCards: Story = {
  render: () => {
    return (
      <DemoStack>
        <h2>Pre trip</h2>
        <Drawer className="position-relative">
          <PreTrip vehicle={vehicle} onReserve={noop} />
        </Drawer>

        <h2>Ongoing trip</h2>
        <Drawer className="position-relative">
          <Trip
            trip={trip}
            onCloseTrip={noop}
            onEndTrip={noop}
            lastLocation={{ latlng: { lat: 1, lng: 1 } }}
          />
        </Drawer>

        <h2>Completed trip</h2>
        <Drawer className="position-relative">
          <PostTrip endTrip={trip} onCloseTrip={noop} />
        </Drawer>

        {/*<h2>Drawer loading</h2>*/}
        {/*<Drawer className"position-relative>*/}
        {/*  <DrawerLoading />*/}
        {/*</Drawer>*/}
      </DemoStack>
    );
  },
};
