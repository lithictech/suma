import scooterIcon from "../assets/images/kick-scooter.png";
import LinearBreadcrumbs from "../components/LinearBreadcrumbs";
import RLink from "../components/RLink";
import { t } from "../localization";
import { dayjs } from "../modules/dayConfig";
import { LayoutContainer } from "../state/withLayout";
import isEmpty from "lodash/isEmpty";
import React from "react";
import { Stack } from "react-bootstrap";
import Card from "react-bootstrap/Card";

export default function MobilityTripList() {
  // const {
  //   state: tripHistory,
  //   loading,
  //   error,
  // } = useAsyncFetch(api.getMobilityTripHistory, {
  //   default: {},
  //   pickData: true,
  // });
  // if (error) {
  //   return (
  //     <LayoutContainer top>
  //       <ErrorScreen />
  //     </LayoutContainer>
  //   );
  // }
  // if (loading) {
  //   return <PageLoader />;
  // }
  const { items } = tripHistory;
  return (
    <>
      <LayoutContainer top gutters>
        <LinearBreadcrumbs back="/mobility" />
        <h2>Mobility Trips</h2>
      </LayoutContainer>
      <LayoutContainer gutters>
        {!isEmpty(items) && (
          <Stack gap={3} className="mt-4">
            <FirstTrip {...items[0]} />
            {items.length > 1 && (
              <>
                <hr className="my-1" />
                {items.map((t) => (
                  <Card key={t.id}>
                    <Card.Body>
                      <TripHeader {...t} />
                    </Card.Body>
                  </Card>
                ))}
              </>
            )}
          </Stack>
        )}
        {isEmpty(items) && <>No mobility trip history</>}
      </LayoutContainer>
    </>
  );
}

function FirstTrip({
  id,
  partner,
  vehicleId,
  total,
  distanceMiles,
  location,
  beganAt,
  endedAt,
}) {
  const headerDetails = { id, partner, vehicleId, total };
  return (
    <Card>
      <Card.Body>
        <Stack direction="vertical" gap={3}>
          <TripHeader {...headerDetails} />
          <div>
            <p className="mb-1">{dayjs(beganAt).format("ll")}</p>
            <p className="mb-1">
              From <b>{dayjs(beganAt).format("LT")}</b> to{" "}
              <b>{dayjs(endedAt).format("LT")}</b>
            </p>
            <p className="mb-1">{distanceMiles} miles traveled</p>
            <p className="mb-1">{location}</p>
          </div>
        </Stack>
      </Card.Body>
    </Card>
  );
}

function TripHeader({ id, partner, vehicleId, total }) {
  return (
    <Stack direction={"horizontal"}>
      <div>
        <img src={scooterIcon} style={{ width: "25px" }} alt="scooter icon" />
        <Card.Link as={RLink} href={`/mobility/${id}`} className="h5 ms-2">
          {partner + " " + vehicleId}
        </Card.Link>
      </div>
      {total.cents === 0 ? (
        <span className="ms-auto text-success">Free Ride</span>
      ) : (
        t("common:total", { total: total })
      )}
    </Stack>
  );
}

// TODO: remove mockup below and return API trip response
const tripHistory = {
  items: [
    {
      id: 1,
      partner: "Lime",
      vehicleId: "#A1B2C3",
      total: { cents: 0, currency: "US" },
      distanceMiles: 3.44,
      location: "Portland, Oregon 22nd/5th Casavana Street",
      beganAt: new Date("2023-04-01 15:22:00"),
      endedAt: new Date("2023-04-02 15:30:00"),
    },
    {
      id: 2,
      partner: "Lime",
      vehicleId: "#A1B2C3",
      total: { cents: 0, currency: "US" },
      distanceMiles: 3.44,
      location: "Portland, Oregon 22nd/5th Casavana Street",
      beganAt: new Date("2023-04-01 15:22:00"),
      endedAt: new Date("2023-04-02 15:30:00"),
    },
    {
      id: 3,
      partner: "Lime",
      vehicleId: "#A1B2C3",
      total: { cents: 0, currency: "US" },
      distanceMiles: 3.44,
      location: "Portland, Oregon 22nd/5th Casavana Street",
      beganAt: new Date("2023-04-01 15:22:00"),
      endedAt: new Date("2023-04-02 15:30:00"),
    },
  ],
};
