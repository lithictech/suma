import TripDetail from "../components/TripDetail.tsx";
import TripList from "../components/TripList.tsx";
import Drawer from "../components/mobilitymap/Drawer.tsx";
import DrawerContentsGeneralError from "../components/mobilitymap/DrawerContentsGeneralError.tsx";
import DrawerContentsLoading from "../components/mobilitymap/DrawerContentsLoading.tsx";
import DrawerContentsOngoingTrip from "../components/mobilitymap/DrawerContentsOngoingTrip.tsx";
import DrawerContentsPostTrip from "../components/mobilitymap/DrawerContentsPostTrip.tsx";
import DrawerContentsPreTrip from "../components/mobilitymap/DrawerContentsPreTrip.tsx";
import DrawerContentsVehicleError from "../components/mobilitymap/DrawerContentsVehicleError.tsx";
import MapWithDrawer from "../components/mobilitymap/MapWithDrawer.tsx";
import { appError } from "../modules/feedback.ts";
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
  undiscountedRate: null,
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

const trip: MobilityTrip = {
  id: 1,
  vehicleId: "vehicle5",
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
  image: null,
};

export const MapCards: Story = {
  render: () => (
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
        <DrawerContentsGeneralError error={appError("read_only_technical_error")} />
      </Drawer>

      <h3>Vehicle error</h3>
      <Drawer noPosition>
        <DrawerContentsVehicleError
          error={appError("read_only_technical_error")}
          provider={mapVendorService}
        />
      </Drawer>
    </DemoStack>
  ),
};

export const Map: Story = {
  render: () => (
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
          content={
            <DrawerContentsGeneralError error={appError("read_only_technical_error")} />
          }
        />
      </div>
    </DemoStack>
  ),
};

export const Trips: Story = {
  render: () => <TripList tripCollection={tripHistory} />,
};

export const NoTrips: Story = {
  render: () => <TripList tripCollection={{ totalCount: 0 } as MobilityTripCollection} />,
};

export const BikeTripDetail: Story = {
  render: () => (
    <TripDetail trip={tripHistory.items.find((x) => x.vehicleType === "ebike")!} />
  ),
};

export const ScooterTripDetail: Story = {
  render: () => (
    <TripDetail trip={tripHistory.items.find((x) => x.vehicleType === "escooter")!} />
  ),
};

const tripHistory: MobilityTripCollection = {
  object: "list",
  currentPage: 1,
  pageCount: 1,
  totalCount: 17,
  hasMore: false,
  url: "/api/v1/mobility/trips",
  items: [
    {
      id: 73962,
      vehicleId: "FNETBL7QRXASE",
      vehicleType: "escooter",
      provider: {
        id: 2,
        name: "Lime E-Scooter",
        slug: "lime_mobility_deeplink",
        vendorName: "Lime",
        vendorSlug: "lime",
      },
      beginLat: 45.548115,
      beginLng: -122.581681,
      beginAddress: null,
      beganAt: "2026-04-13T07:20:00.000+00:00",
      endLat: 45.542337,
      endLng: -122.603734,
      endAddress: null,
      endedAt: "2026-04-13T07:27:00.000+00:00",
      ongoing: false,
      charge: {
        undiscountedCost: { cents: 205, currency: "USD" },
        customerCost: { cents: 0, currency: "USD" },
        savings: { cents: 205, currency: "USD" },
        lineItems: [
          { amount: { cents: 0, currency: "USD" }, memo: "Unlock fee" },
          { amount: { cents: 0, currency: "USD" }, memo: "Riding - $0.00/min (7 min)" },
        ],
      },
      minutes: 7,
      image: null,
    },
    {
      id: 74116,
      vehicleId: "U3K6SAN25USZ3",
      vehicleType: "escooter",
      provider: {
        id: 2,
        name: "Lime E-Scooter",
        slug: "lime_mobility_deeplink",
        vendorName: "Lime",
        vendorSlug: "lime",
      },
      beginLat: 45.547909,
      beginLng: -122.589861,
      beginAddress: null,
      beganAt: "2026-04-12T19:19:00.000+00:00",
      endLat: 45.548094,
      endLng: -122.581676,
      endAddress: null,
      endedAt: "2026-04-12T19:23:00.000+00:00",
      ongoing: false,
      charge: {
        undiscountedCost: { cents: 160, currency: "USD" },
        customerCost: { cents: 0, currency: "USD" },
        savings: { cents: 160, currency: "USD" },
        lineItems: [
          { amount: { cents: 0, currency: "USD" }, memo: "Unlock fee" },
          { amount: { cents: 0, currency: "USD" }, memo: "Riding - $0.00/min (4 min)" },
        ],
      },
      minutes: 4,
      image: null,
    },
    {
      id: 73727,
      vehicleId: "L5K4WRBLHFHIA",
      vehicleType: "escooter",
      provider: {
        id: 2,
        name: "Lime E-Scooter",
        slug: "lime_mobility_deeplink",
        vendorName: "Lime",
        vendorSlug: "lime",
      },
      beginLat: 45.522606,
      beginLng: -122.634084,
      beginAddress: null,
      beganAt: "2026-04-03T15:58:00.000+00:00",
      endLat: 45.522192,
      endLng: -122.637157,
      endAddress: null,
      endedAt: "2026-04-03T16:02:00.000+00:00",
      ongoing: false,
      charge: {
        undiscountedCost: { cents: 160, currency: "USD" },
        customerCost: { cents: 0, currency: "USD" },
        savings: { cents: 160, currency: "USD" },
        lineItems: [
          { amount: { cents: 0, currency: "USD" }, memo: "Unlock fee" },
          { amount: { cents: 0, currency: "USD" }, memo: "Riding - $0.00/min (4 min)" },
        ],
      },
      minutes: 4,
      image: null,
    },
    {
      id: 72044,
      vehicleId: "SZA7CNRSWBSDE",
      vehicleType: "escooter",
      provider: {
        id: 2,
        name: "Lime E-Scooter",
        slug: "lime_mobility_deeplink",
        vendorName: "Lime",
        vendorSlug: "lime",
      },
      beginLat: 45.542047,
      beginLng: -122.615959,
      beginAddress: null,
      beganAt: "2026-03-09T17:44:00.000+00:00",
      endLat: 45.545372,
      endLng: -122.612676,
      endAddress: null,
      endedAt: "2026-03-09T17:48:00.000+00:00",
      ongoing: false,
      charge: {
        undiscountedCost: { cents: 160, currency: "USD" },
        customerCost: { cents: 0, currency: "USD" },
        savings: { cents: 160, currency: "USD" },
        lineItems: [
          { amount: { cents: 0, currency: "USD" }, memo: "Unlock fee" },
          { amount: { cents: 0, currency: "USD" }, memo: "Riding - $0.00/min (4 min)" },
        ],
      },
      minutes: 4,
      image: null,
    },
    {
      id: 71831,
      vehicleId: "5DFZWXFGVNAKZ",
      vehicleType: "escooter",
      provider: {
        id: 2,
        name: "Lime E-Scooter",
        slug: "lime_mobility_deeplink",
        vendorName: "Lime",
        vendorSlug: "lime",
      },
      beginLat: 45.543671,
      beginLng: -122.606608,
      beginAddress: null,
      beganAt: "2026-03-06T11:23:00.000+00:00",
      endLat: 45.542172,
      endLng: -122.608578,
      endAddress: null,
      endedAt: "2026-03-06T11:25:00.000+00:00",
      ongoing: false,
      charge: {
        undiscountedCost: { cents: 130, currency: "USD" },
        customerCost: { cents: 0, currency: "USD" },
        savings: { cents: 130, currency: "USD" },
        lineItems: [
          { amount: { cents: 0, currency: "USD" }, memo: "Unlock fee" },
          { amount: { cents: 0, currency: "USD" }, memo: "Riding - $0.00/min (2 min)" },
        ],
      },
      minutes: 2,
      image: null,
    },
    {
      id: 33772,
      vehicleId: "2112629298058814556",
      vehicleType: "ebike",
      provider: {
        id: 36,
        name: "Biketown E-Bike",
        slug: "biketown_mobility_deeplink",
        vendorName: "Biketown",
        vendorSlug: "biketown",
      },
      beginLat: 0.0,
      beginLng: 0.0,
      beginAddress: { part1: "2128 SE Division St", part2: "Portland, OR 97202" },
      beganAt: "2025-08-03T02:40:41.000+00:00",
      endLat: 0.0,
      endLng: 0.0,
      endAddress: { part1: "2839 SE Stark St", part2: "Portland, OR 97214" },
      endedAt: "2025-08-03T02:53:30.000+00:00",
      ongoing: false,
      charge: {
        undiscountedCost: { cents: 555, currency: "USD" },
        customerCost: { cents: 0, currency: "USD" },
        savings: { cents: 555, currency: "USD" },
        lineItems: [
          { amount: { cents: 100, currency: "USD" }, memo: "Unlock fee" },
          {
            amount: { cents: 455, currency: "USD" },
            memo: "Riding - $0.35/min (13 min)",
          },
          {
            amount: { cents: -555, currency: "USD" },
            memo: "Subsidy from local funders",
          },
        ],
      },
      minutes: 13,
      image: {
        caption: "",
        url: "https://app.mysuma.org/api/v1/images/im_e9ur4tq2g91iogpisxejrk9au",
      },
    },
    {
      id: 33770,
      vehicleId: "2112603352165253186",
      vehicleType: "ebike",
      provider: {
        id: 36,
        name: "Biketown E-Bike",
        slug: "biketown_mobility_deeplink",
        vendorName: "Biketown",
        vendorSlug: "biketown",
      },
      beginLat: 0.0,
      beginLng: 0.0,
      beginAddress: { part1: "2900 SE Belmont St", part2: "Portland, OR 97214" },
      beganAt: "2025-08-03T01:00:00.000+00:00",
      endLat: 0.0,
      endLng: 0.0,
      endAddress: { part1: "2132 SE Division St", part2: "Portland, OR 97202" },
      endedAt: "2025-08-03T01:07:25.000+00:00",
      ongoing: false,
      charge: {
        undiscountedCost: { cents: 380, currency: "USD" },
        customerCost: { cents: 0, currency: "USD" },
        savings: { cents: 380, currency: "USD" },
        lineItems: [
          { amount: { cents: 100, currency: "USD" }, memo: "Unlock fee" },
          { amount: { cents: 280, currency: "USD" }, memo: "Riding - $0.35/min (8 min)" },
          {
            amount: { cents: -380, currency: "USD" },
            memo: "Subsidy from local funders",
          },
        ],
      },
      minutes: 8,
      image: {
        caption: "",
        url: "https://app.mysuma.org/api/v1/images/im_ddthtboqualpt9hjsgbb47uwh",
      },
    },
    {
      id: 33723,
      vehicleId: "2105118948739619654",
      vehicleType: "ebike",
      provider: {
        id: 36,
        name: "Biketown E-Bike",
        slug: "biketown_mobility_deeplink",
        vendorName: "Biketown",
        vendorSlug: "biketown",
      },
      beginLat: 0.0,
      beginLng: 0.0,
      beginAddress: { part1: "5704 SE 92nd Ave", part2: "Portland, OR 97266" },
      beganAt: "2025-07-13T20:56:44.000+00:00",
      endLat: 0.0,
      endLng: 0.0,
      endAddress: { part1: "2323 SE 82nd Ave", part2: "Portland, OR 97216" },
      endedAt: "2025-07-13T21:19:28.000+00:00",
      ongoing: false,
      charge: {
        undiscountedCost: { cents: 905, currency: "USD" },
        customerCost: { cents: 0, currency: "USD" },
        savings: { cents: 905, currency: "USD" },
        lineItems: [
          { amount: { cents: 100, currency: "USD" }, memo: "Unlock fee" },
          {
            amount: { cents: 805, currency: "USD" },
            memo: "Riding - $0.35/min (23 min)",
          },
          {
            amount: { cents: -905, currency: "USD" },
            memo: "Subsidy from local funders",
          },
        ],
      },
      minutes: 23,
      image: {
        caption: "",
        url: "https://app.mysuma.org/api/v1/images/im_8wtfia4h8ftgh2tngh286xabl",
      },
    },
    {
      id: 33707,
      vehicleId: "2105101169262042852",
      vehicleType: "ebike",
      provider: {
        id: 36,
        name: "Biketown E-Bike",
        slug: "biketown_mobility_deeplink",
        vendorName: "Biketown",
        vendorSlug: "biketown",
      },
      beginLat: 0.0,
      beginLng: 0.0,
      beginAddress: { part1: "8135 SE Division St", part2: "Portland, OR 97216" },
      beganAt: "2025-07-13T19:47:41.000+00:00",
      endLat: 0.0,
      endLng: 0.0,
      endAddress: { part1: "5704 SE 92nd Ave", part2: "Portland, OR 97266" },
      endedAt: "2025-07-13T20:20:11.000+00:00",
      ongoing: false,
      charge: {
        undiscountedCost: { cents: 1255, currency: "USD" },
        customerCost: { cents: 0, currency: "USD" },
        savings: { cents: 1255, currency: "USD" },
        lineItems: [
          { amount: { cents: 100, currency: "USD" }, memo: "Unlock fee" },
          {
            amount: { cents: 1155, currency: "USD" },
            memo: "Riding - $0.35/min (33 min)",
          },
          {
            amount: { cents: -1255, currency: "USD" },
            memo: "Subsidy from local funders",
          },
        ],
      },
      minutes: 33,
      image: {
        caption: "",
        url: "https://app.mysuma.org/api/v1/images/im_dsyaywokluvk590rgskjb7mfn",
      },
    },
    {
      id: 33704,
      vehicleId: "2105099991463465488",
      vehicleType: "ebike",
      provider: {
        id: 36,
        name: "Biketown E-Bike",
        slug: "biketown_mobility_deeplink",
        vendorName: "Biketown",
        vendorSlug: "biketown",
      },
      beginLat: 0.0,
      beginLng: 0.0,
      beginAddress: { part1: "8135 SE Division St", part2: "Portland, OR 97216" },
      beganAt: "2025-07-13T19:43:07.000+00:00",
      endLat: 0.0,
      endLng: 0.0,
      endAddress: { part1: "2323 SE 82nd Ave", part2: "Portland, OR 97216" },
      endedAt: "2025-07-13T19:45:29.000+00:00",
      ongoing: false,
      charge: {
        undiscountedCost: { cents: 205, currency: "USD" },
        customerCost: { cents: 0, currency: "USD" },
        savings: { cents: 205, currency: "USD" },
        lineItems: [
          { amount: { cents: 100, currency: "USD" }, memo: "Unlock fee" },
          { amount: { cents: 105, currency: "USD" }, memo: "Riding - $0.35/min (3 min)" },
          {
            amount: { cents: -205, currency: "USD" },
            memo: "Subsidy from local funders",
          },
        ],
      },
      minutes: 3,
      image: {
        caption: "",
        url: "https://app.mysuma.org/api/v1/images/im_d362fia2a5ybv2b6mepnvr7yx",
      },
    },
    {
      id: 33701,
      vehicleId: "2105051627425822078",
      vehicleType: "ebike",
      provider: {
        id: 36,
        name: "Biketown E-Bike",
        slug: "biketown_mobility_deeplink",
        vendorName: "Biketown",
        vendorSlug: "biketown",
      },
      beginLat: 0.0,
      beginLng: 0.0,
      beginAddress: { part1: "2839 SE Stark St", part2: "Portland, OR 97214" },
      beganAt: "2025-07-13T16:35:26.000+00:00",
      endLat: 0.0,
      endLng: 0.0,
      endAddress: { part1: "2839 SE Stark St", part2: "Portland, OR 97214" },
      endedAt: "2025-07-13T16:38:58.000+00:00",
      ongoing: false,
      charge: {
        undiscountedCost: { cents: 240, currency: "USD" },
        customerCost: { cents: 0, currency: "USD" },
        savings: { cents: 240, currency: "USD" },
        lineItems: [
          { amount: { cents: 100, currency: "USD" }, memo: "Unlock fee" },
          { amount: { cents: 140, currency: "USD" }, memo: "Riding - $0.35/min (4 min)" },
          {
            amount: { cents: -240, currency: "USD" },
            memo: "Subsidy from local funders",
          },
        ],
      },
      minutes: 4,
      image: {
        caption: "",
        url: "https://app.mysuma.org/api/v1/images/im_9uqlriq3v7ygzl2x67r6fz0m9",
      },
    },
    {
      id: 33658,
      vehicleId: "2088517065665742796",
      vehicleType: "ebike",
      provider: {
        id: 36,
        name: "Biketown E-Bike",
        slug: "biketown_mobility_deeplink",
        vendorName: "Biketown",
        vendorSlug: "biketown",
      },
      beginLat: 0.0,
      beginLng: 0.0,
      beginAddress: { part1: "622 NE Grand Ave", part2: "Portland, OR 97232" },
      beganAt: "2025-05-30T03:12:54.000+00:00",
      endLat: 0.0,
      endLng: 0.0,
      endAddress: { part1: "2839 SE Stark St", part2: "Portland, OR 97214" },
      endedAt: "2025-05-30T03:22:48.000+00:00",
      ongoing: false,
      charge: {
        undiscountedCost: { cents: 450, currency: "USD" },
        customerCost: { cents: 0, currency: "USD" },
        savings: { cents: 450, currency: "USD" },
        lineItems: [
          { amount: { cents: 100, currency: "USD" }, memo: "Unlock fee" },
          {
            amount: { cents: 350, currency: "USD" },
            memo: "Riding - $0.35/min (10 min)",
          },
          {
            amount: { cents: -450, currency: "USD" },
            memo: "Subsidy from local funders",
          },
        ],
      },
      minutes: 10,
      image: {
        caption: "",
        url: "https://app.mysuma.org/api/v1/images/im_bbpq2lujbflqh6zvpjz46meog",
      },
    },
    {
      id: 33657,
      vehicleId: "2088474992572727934",
      vehicleType: "ebike",
      provider: {
        id: 36,
        name: "Biketown E-Bike",
        slug: "biketown_mobility_deeplink",
        vendorName: "Biketown",
        vendorSlug: "biketown",
      },
      beginLat: 0.0,
      beginLng: 0.0,
      beginAddress: { part1: "2839 SE Stark St", part2: "Portland, OR 97214" },
      beganAt: "2025-05-30T00:29:38.000+00:00",
      endLat: 0.0,
      endLng: 0.0,
      endAddress: { part1: "622 NE Grand Ave", part2: "Portland, OR 97232" },
      endedAt: "2025-05-30T00:43:03.000+00:00",
      ongoing: false,
      charge: {
        undiscountedCost: { cents: 590, currency: "USD" },
        customerCost: { cents: 0, currency: "USD" },
        savings: { cents: 590, currency: "USD" },
        lineItems: [
          { amount: { cents: 100, currency: "USD" }, memo: "Unlock fee" },
          {
            amount: { cents: 490, currency: "USD" },
            memo: "Riding - $0.35/min (14 min)",
          },
          {
            amount: { cents: -590, currency: "USD" },
            memo: "Subsidy from local funders",
          },
        ],
      },
      minutes: 14,
      image: {
        caption: "",
        url: "https://app.mysuma.org/api/v1/images/im_3bnaca4lmgv59qjuetrhjjgu9",
      },
    },
    {
      id: 33614,
      vehicleId: "2072137373917253308",
      vehicleType: "ebike",
      provider: {
        id: 36,
        name: "Biketown E-Bike",
        slug: "biketown_mobility_deeplink",
        vendorName: "Biketown",
        vendorSlug: "biketown",
      },
      beginLat: 0.0,
      beginLng: 0.0,
      beginAddress: { part1: "2839 SE Stark St", part2: "Portland, OR 97214" },
      beganAt: "2025-04-15T23:51:19.000+00:00",
      endLat: 0.0,
      endLng: 0.0,
      endAddress: { part1: "2839 SE Stark St", part2: "Portland, OR 97214" },
      endedAt: "2025-04-15T23:54:09.000+00:00",
      ongoing: false,
      charge: {
        undiscountedCost: { cents: 205, currency: "USD" },
        customerCost: { cents: 0, currency: "USD" },
        savings: { cents: 205, currency: "USD" },
        lineItems: [
          { amount: { cents: 100, currency: "USD" }, memo: "Unlock fee" },
          { amount: { cents: 105, currency: "USD" }, memo: "Riding - $0.35/min (3 min)" },
          {
            amount: { cents: -205, currency: "USD" },
            memo: "Subsidy from local funders",
          },
        ],
      },
      minutes: 3,
      image: {
        caption: "",
        url: "https://app.mysuma.org/api/v1/images/im_d6v7w7r0gms7b25i1wlv8h2hj",
      },
    },
    {
      id: 44684,
      vehicleId: "U7T7ZSZJRG6XZ",
      vehicleType: "escooter",
      provider: {
        id: 2,
        name: "Lime E-Scooter",
        slug: "lime_mobility_deeplink",
        vendorName: "Lime",
        vendorSlug: "lime",
      },
      beginLat: 45.589815,
      beginLng: -122.750203,
      beginAddress: null,
      beganAt: "2024-08-03T16:00:00.000+00:00",
      endLat: 45.591091,
      endLng: -122.750511,
      endAddress: null,
      endedAt: "2024-08-03T16:02:00.000+00:00",
      ongoing: false,
      charge: {
        undiscountedCost: { cents: 130, currency: "USD" },
        customerCost: { cents: 0, currency: "USD" },
        savings: { cents: 130, currency: "USD" },
        lineItems: [
          { amount: { cents: 0, currency: "USD" }, memo: "Unlock fee" },
          { amount: { cents: 0, currency: "USD" }, memo: "Riding - $0.00/min (2 min)" },
        ],
      },
      minutes: 2,
      image: null,
    },
    {
      id: 44615,
      vehicleId: "XL4MPVDOBOXO4",
      vehicleType: "escooter",
      provider: {
        id: 2,
        name: "Lime E-Scooter",
        slug: "lime_mobility_deeplink",
        vendorName: "Lime",
        vendorSlug: "lime",
      },
      beginLat: 45.557113,
      beginLng: -122.658985,
      beginAddress: null,
      beganAt: "2024-07-14T21:11:00.000+00:00",
      endLat: 45.589967,
      endLng: -122.715796,
      endAddress: null,
      endedAt: "2024-07-14T21:42:00.000+00:00",
      ongoing: false,
      charge: {
        undiscountedCost: { cents: 565, currency: "USD" },
        customerCost: { cents: 0, currency: "USD" },
        savings: { cents: 565, currency: "USD" },
        lineItems: [
          { amount: { cents: 0, currency: "USD" }, memo: "Unlock fee" },
          { amount: { cents: 0, currency: "USD" }, memo: "Riding - $0.00/min (31 min)" },
        ],
      },
      minutes: 31,
      image: null,
    },
    {
      id: 44613,
      vehicleId: "BY4UFJAAAZQJR",
      vehicleType: "escooter",
      provider: {
        id: 2,
        name: "Lime E-Scooter",
        slug: "lime_mobility_deeplink",
        vendorName: "Lime",
        vendorSlug: "lime",
      },
      beginLat: 45.557081,
      beginLng: -122.658991,
      beginAddress: null,
      beganAt: "2024-07-14T19:04:00.000+00:00",
      endLat: 45.557091,
      endLng: -122.658978,
      endAddress: null,
      endedAt: "2024-07-14T19:28:00.000+00:00",
      ongoing: false,
      charge: {
        undiscountedCost: { cents: 460, currency: "USD" },
        customerCost: { cents: 0, currency: "USD" },
        savings: { cents: 460, currency: "USD" },
        lineItems: [
          { amount: { cents: 0, currency: "USD" }, memo: "Unlock fee" },
          { amount: { cents: 0, currency: "USD" }, memo: "Riding - $0.00/min (24 min)" },
        ],
      },
      minutes: 24,
      image: null,
    },
  ],
  ongoing: null,
  weeks: [
    { beginAt: "2026-04-13", endAt: "2026-04-19", beginIndex: 0, endIndex: 1 },
    { beginAt: "2026-04-06", endAt: "2026-04-12", beginIndex: 1, endIndex: 2 },
    { beginAt: "2026-03-30", endAt: "2026-04-05", beginIndex: 2, endIndex: 3 },
    { beginAt: "2026-03-09", endAt: "2026-03-15", beginIndex: 3, endIndex: 4 },
    { beginAt: "2026-03-02", endAt: "2026-03-08", beginIndex: 4, endIndex: 5 },
    { beginAt: "2025-07-28", endAt: "2025-08-03", beginIndex: 5, endIndex: 7 },
    { beginAt: "2025-07-07", endAt: "2025-07-13", beginIndex: 7, endIndex: 11 },
    { beginAt: "2025-05-26", endAt: "2025-06-01", beginIndex: 11, endIndex: 13 },
    { beginAt: "2025-04-14", endAt: "2025-04-20", beginIndex: 13, endIndex: 14 },
    { beginAt: "2024-07-29", endAt: "2024-08-04", beginIndex: 14, endIndex: 15 },
    { beginAt: "2024-07-08", endAt: "2024-07-14", beginIndex: 15, endIndex: 17 },
  ],
};
