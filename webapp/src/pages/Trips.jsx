import api from "../api";
import ErrorScreen from "../components/ErrorScreen";
import LayoutContainer from "../components/LayoutContainer";
import PageLoader from "../components/PageLoader";
import { t } from "../localization";
import { vehicleIconForVendorService } from "../modules/mobilityIconLookup.js";
import Money from "../shared/react/Money.jsx";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import useUrlMarshal from "../shared/react/useUrlMarshal.js";
import dayjs from "dayjs";
import isEmpty from "lodash/isEmpty";
import React from "react";
import Stack from "react-bootstrap/Stack";
import { Link } from "react-router-dom";

export default function Trips() {
  const {
    state: trips,
    loading: tripsLoading,
    error: tripsError,
  } = useAsyncFetch(api.getMobilityTrips, {
    default: {},
    pickData: true,
  });

  if (tripsError) {
    return (
      <LayoutContainer top>
        <ErrorScreen />
      </LayoutContainer>
    );
  }

  return (
    <>
      <LayoutContainer gutters>
        <h2>{t("titles.trips")}</h2>
        <p className="text-secondary">{t("trips.intro")}</p>
      </LayoutContainer>
      {tripsLoading ? (
        <PageLoader />
      ) : isEmpty(trips.items) ? (
        <LayoutContainer>{t("trips.empty")}</LayoutContainer>
      ) : (
        <LayoutContainer className="px-0">
          <Stack>
            {trips.weeks.map((w) => (
              <React.Fragment key={w.beginAt}>
                <div className="trips-week-divider" />
                <Week items={trips.items} {...w}></Week>
              </React.Fragment>
            ))}
          </Stack>
        </LayoutContainer>
      )}
    </>
  );
}

function Week({ items, beginAt, endAt, beginIndex, endIndex }) {
  const trips = items.slice(beginIndex, endIndex);
  return (
    <Stack direction="vertical" gap={0.5}>
      <h4 className="my-3 mx-3">
        {dayjs(beginAt).format("ll")} &mdash; {dayjs(endAt).format("ll")}
      </h4>
      {trips.map((a, i) => (
        <React.Fragment key={a.id}>
          <Trip trip={a} />
          {i < trips.length - 1 && <hr className="mx-3 my-0" />}
        </React.Fragment>
      ))}
    </Stack>
  );
}

function Trip({ trip }) {
  const { marshalToUrl } = useUrlMarshal();
  const { id, vehicleType, provider, beganAt, charge } = trip;
  return (
    <Link to={`/trip/${id}?${marshalToUrl("trip", trip)}`} className="link-unstyled">
      <Stack direction="horizontal" className="justify-content-between p-3">
        <Stack direction="horizontal" gap={3}>
          <img
            src={vehicleIconForVendorService(vehicleType, provider.slug)}
            alt={`${provider.slug} ${vehicleType}`}
            height={42}
            className="trips-image-vehicle"
          />
          <Stack direction="vertical" className="small">
            <div className="me-3">
              {t("trips.ride_description", {
                vendor: provider.vendorName,
                vehicleType: t(`trips.${vehicleType}`),
              })}{" "}
              &bull; {t(`trips.minutes`, { minutes: trip.minutes })}
            </div>
            <div className="text-muted">{dayjs(beganAt).format("MMM D, LT")}</div>
          </Stack>
        </Stack>
        <div>
          <Money>{charge.customerCost}</Money>
        </div>
      </Stack>
    </Link>
  );
}
