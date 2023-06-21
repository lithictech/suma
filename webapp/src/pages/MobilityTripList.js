import api from "../api";
import scooterIcon from "../assets/images/kick-scooter.png";
import ErrorScreen from "../components/ErrorScreen";
import LinearBreadcrumbs from "../components/LinearBreadcrumbs";
import PageLoader from "../components/PageLoader";
import RLink from "../components/RLink";
import { t } from "../localization";
import { dayjs } from "../modules/dayConfig";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import { LayoutContainer } from "../state/withLayout";
import isEmpty from "lodash/isEmpty";
import React from "react";
import { Stack } from "react-bootstrap";
import Card from "react-bootstrap/Card";

export default function MobilityTripList() {
  const {
    state: tripHistory,
    loading,
    error,
  } = useAsyncFetch(api.getMobilityTrips, {
    default: {},
    pickData: true,
  });
  if (error) {
    return (
      <LayoutContainer top>
        <ErrorScreen />
      </LayoutContainer>
    );
  }
  if (loading) {
    return <PageLoader />;
  }
  const { items } = tripHistory;
  // TODO: translate english text to spanish
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
                      <TripHeader {...t} providerName={t.provider?.name} />
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

function FirstTrip({ id, provider, totalCost, beganAt, endedAt }) {
  return (
    <Card>
      <Card.Body>
        <Stack direction="vertical" gap={3}>
          <TripHeader id={id} providerName={provider?.name} totalCost={totalCost} />
          <div>
            <p className="mb-1">{dayjs(beganAt).format("ll")}</p>
            <p className="mb-1">
              From <b>{dayjs(beganAt).format("LT")}</b> to{" "}
              <b>{dayjs(endedAt).format("LT")}</b>
            </p>
          </div>
        </Stack>
      </Card.Body>
    </Card>
  );
}

function TripHeader({ id, providerName, totalCost }) {
  return (
    <Stack direction={"horizontal"}>
      <div>
        <img src={scooterIcon} style={{ width: "25px" }} alt="scooter icon" />
        <Card.Link as={RLink} href={`/mobility/${id}`} className="h5 ms-2">
          {providerName}
        </Card.Link>
      </div>
      {totalCost.cents === 0 ? (
        <span className="ms-auto text-success">Free Ride</span>
      ) : (
        t("common:total", { total: totalCost })
      )}
    </Stack>
  );
}
