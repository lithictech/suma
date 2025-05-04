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

export default function TripDetail() {
  const { unmarshalFromUrl } = useUrlMarshal();
  let trip;
  try {
    trip = unmarshalFromUrl("trip", window.location.href);
  } catch (e) {
    return (
      <LayoutContainer top>
        <ErrorScreen />
      </LayoutContainer>
    );
  }
  const { id, vehicleType, provider, beganAt, endedAt, charge } = trip;

  return (
    <>
      <LayoutContainer className="px-0">
        <Link to="/trips" className="link-unstyled">
          <h4 className="ms-3">
            {t("common:back_sym")} {dayjs(beganAt).format("ll")}
          </h4>
        </Link>
        <Stack direction="vertical" gap={3} className="align-items-center p-3">
          <div style={{ height: 60 }}>
            <img
              src={vehicleIconForVendorService(vehicleType, provider.slug)}
              alt={`${provider.slug} ${vehicleType}`}
              className="trips-image-vehicle"
              height={60}
            />
          </div>
          <Money as="h4" className="mb-0">
            {charge.customerCost}
          </Money>
          <p className="mb-0">{t("trips:thanks")}</p>
        </Stack>
        <div className="trips-week-divider" />
        <Stack direction="vertical" gap={3} className="p-3">
          <h4>{t("trips:your_trip")}</h4>
          <div>
            {t("trips:start")} {dayjs(beganAt).format("LT")}
          </div>
          <div>
            {t("trips:end")} {dayjs(endedAt).format("LT")}
          </div>
        </Stack>
        <div className="trips-week-divider" />
        <Stack direction="vertical" gap={3} className="p-3">
          <h4>{t("trips:payment")}</h4>
          {charge.lineItems.map(({ memo, amount }) => (
            <Stack key={memo} direction="horizontal" className="justify-content-between">
              <div>{memo}</div>
              <Money>{amount}</Money>
            </Stack>
          ))}
        </Stack>
      </LayoutContainer>
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
