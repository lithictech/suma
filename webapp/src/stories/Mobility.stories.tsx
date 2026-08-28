import Drawer from "../components/mobilitymap/Drawer.tsx";
import DrawerContentsLoading from "../components/mobilitymap/DrawerContentsLoading.tsx";
import DrawerContentsOngoingTrip from "../components/mobilitymap/DrawerContentsOngoingTrip.tsx";
import DrawerContentsPageError from "../components/mobilitymap/DrawerContentsPageError.tsx";
import DrawerContentsPostTrip from "../components/mobilitymap/DrawerContentsPostTrip.tsx";
import DrawerContentsPreTrip from "../components/mobilitymap/DrawerContentsPreTrip.tsx";
import DrawerContentsVehicleError from "../components/mobilitymap/DrawerContentsVehicleError.tsx";
import MapWithDrawer from "../components/mobilitymap/MapWithDrawer.tsx";
import { DemoStack } from "./helpers.tsx";
import mapBackgroundPng from "./map-background.png";
import type { Meta, StoryObj } from "@storybook/preact-vite";
import noop from "lodash/noop";

const meta = {
  title: "Styleguide/Mobility",
} satisfies Meta;

export default meta;
type Story = StoryObj<typeof meta>;

const vendorService: VendorService = {
  id: 2,
  name: "Bikeshare",
  slug: "bikeshare",
  vendorName: "Bikeshare Operator",
  vendorSlug: "bikeop",
};

const baseRate: Rate = {
  id: 50,
  surcharge: { cents: 100, currency: "USD" },
  unitAmount: { cents: 20, currency: "USD" },
  name: "demo",
  undiscountedRate: null as Rate,
};

const mapVendorService: MobilityMapProvider = {
  ...vendorService,
  usageProhibitedReason: "usage_prohibited_cash_balance",
  rate: baseRate,
};

const baseVehicle = {
  precision: 1,
  vendorService,
  vehicleId: "vehicle1",
  loc: [40, 120],
  rate: baseRate,
  subsidyMatchPercentage: 0,
  deeplink: "",
  gotoPrivateAccount: "",
  usageProhibitedReason: "",
};

const prohibitedVehicle = {
  ...baseVehicle,
  usageProhibitedReason: "usage_prohibited_cash_balance",
};

const deeplinkVehicle = {
  ...baseVehicle,
  deeplink: "#deeplink",
};

const privateAccountVehicle = {
  ...baseVehicle,
  gotoPrivateAccount: "#private-accounts",
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

        <h3>Deeplink</h3>
        <Drawer noPosition>
          <DrawerContentsPreTrip vehicle={deeplinkVehicle} onReserve={noop} />
        </Drawer>
        <h3>Go-to private account</h3>
        <Drawer noPosition>
          <DrawerContentsPreTrip vehicle={privateAccountVehicle} onReserve={noop} />
        </Drawer>
        <h3>Usage prohibited</h3>
        <Drawer noPosition>
          <DrawerContentsPreTrip vehicle={prohibitedVehicle} onReserve={noop} />
        </Drawer>
        <h3>With subsidy</h3>
        <Drawer noPosition>
          <DrawerContentsPreTrip
            vehicle={{ ...deeplinkVehicle, subsidyMatchPercentage: 20 }}
            onReserve={noop}
          />
        </Drawer>

        <h2>Ongoing trip</h2>

        <Drawer noPosition>
          <DrawerContentsOngoingTrip
            trip={trip}
            onCloseTrip={noop}
            onEndTrip={noop}
            lastLocation={{ latlng: { lat: 1, lng: 1 } }}
          />
        </Drawer>

        <h2>Completed trip</h2>

        <Drawer noPosition>
          <DrawerContentsPostTrip endTrip={trip} onCloseTrip={noop} />
        </Drawer>

        <h2>Misc States</h2>

        <h3>Loading</h3>
        <Drawer noPosition>
          <DrawerContentsLoading />
        </Drawer>

        <h3>Page error</h3>
        <Drawer noPosition>
          <DrawerContentsPageError error="read_only_technical_error" />
        </Drawer>

        <h3>Vehicle error</h3>
        <Drawer noPosition>
          <DrawerContentsVehicleError
            error="read_only_technical_error"
            provider={mapVendorService}
          />
        </Drawer>
      </DemoStack>
    );
  },
};

export const Map: Story = {
  render: () => {
    return (
      <DemoStack>
        <h2>Map with Card</h2>
        <div style={{ width: 360, height: 500 }}>
          <MapWithDrawer
            map={
              <img
                src={mapBackgroundPng}
                alt=""
                height={500}
                width={360}
                style={{ objectFit: "cover", objectPosition: "bottom" }}
              />
            }
            content={<DrawerContentsPageError error="read_only_technical_error" />}
          />
        </div>
      </DemoStack>
    );
  },
};
