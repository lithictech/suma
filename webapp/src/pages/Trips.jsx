import api from "../api";
import ErrorScreen from "../components/ErrorScreen";
import LayoutContainer from "../components/LayoutContainer";
import PageLoader from "../components/PageLoader";
import { t } from "../localization";
import { vehicleIconForVendorService } from "../modules/mobilityIconLookup.js";
import Money from "../shared/react/Money.jsx";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import dayjs from "dayjs";
import isEmpty from "lodash/isEmpty";
import React from "react";
import Stack from "react-bootstrap/Stack";

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
      <LayoutContainer gutters top>
        <h2>{t("titles:trips")}</h2>
        <p className="text-secondary">{t("trips:intro")}</p>
      </LayoutContainer>
      {tripsLoading ? (
        <PageLoader />
      ) : isEmpty(trips.items) ? (
        <LayoutContainer>{t("trips:empty")}</LayoutContainer>
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
  const { id, vehicleType, provider, beganAt, charge } = trip;
  // const trip = {
  //   id: 4,
  //   vehicle_id: "suma-9f3dd8119caa5745e4cf439e3bd3b16a",
  //   vehicle_type: "ebike",
  //   provider: {
  //     id: 37,
  //     name: "Suma Testing",
  //     slug: "suma_testing",
  //     vendor_name: "Suma Testing",
  //     vendor_slug: "suma_testing",
  //   },
  //   rate: {
  //     id: 38,
  //     localization_key: "ut",
  //     localization_vars: {
  //       unit_cents: 0,
  //       unit_currency: "USD",
  //       surcharge_cents: 0,
  //       surcharge_currency: "USD",
  //     },
  //   },
  //   begin_lat: "45.5157855",
  //   begin_lng: "-122.601258",
  //   began_at: "2025-04-04T16:09:44.154+00:00",
  //   end_lat: "45.51454326700422",
  //   end_lng: "-122.6019944355803",
  //   ended_at: "2025-04-04T16:09:50.652+00:00",
  //   ongoing: false,
  //   charge: {
  //     undiscounted_cost: { cents: 0, currency: "USD" },
  //     customer_cost: { cents: 0, currency: "USD" },
  //     savings: { cents: 0, currency: "USD" },
  //   },
  // };
  return (
    <Stack
      direction="horizontal"
      href={`/trips/${id}`}
      className="justify-content-between p-3"
    >
      <Stack direction="horizontal" gap={3}>
        <img
          src={vehicleIconForVendorService(vehicleType, provider.slug)}
          height={42}
          className="trips-image-vehicle"
        />
        <Stack direction="vertical" className="small">
          <div>
            {provider.vendorName} {t(`trips:${vehicleType}`)} {t(`trips:ride`)} &bull;{" "}
            {t(`trips:minutes`, { minutes: trip.minutes })}
          </div>
          <div className="text-muted">{dayjs(beganAt).format("MMM D, LT")}</div>
        </Stack>
      </Stack>
      <div>
        <Money>{charge.customerCost}</Money>
      </div>
    </Stack>
  );
}
