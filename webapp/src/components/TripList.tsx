import { t } from "../localization";
import { dayjs } from "../modules/dayConfig.ts";
import { vehicleIconForVendorService } from "../modules/mobilityIconLookup";
import { withQuery } from "../routing/withQuery.ts";
import useUrlMarshal from "../state/useUrlMarshal";
import DivLink from "../ui/DivLink.tsx";
import Icon from "../ui/Icon.tsx";
import Stack from "../ui/Stack";
import Money from "../uir/Money";
import "./TripList.css";
import React from "react";

interface TripListProps {
  tripCollection: MobilityTripCollection;
}

export default function TripList({ tripCollection }: TripListProps) {
  if (!tripCollection.totalCount) {
    return t("trips.empty");
  }
  return (
    <Stack col gap={4}>
      {tripCollection.weeks.map((w, i) => (
        <React.Fragment key={w.beginAt}>
          {i > 0 && <div className="trips-week-divider" />}
          <Week items={tripCollection.items} {...w}></Week>
        </React.Fragment>
      ))}
    </Stack>
  );
}

interface WeekProps extends MobilityTripCollectionWeek {
  items: MobilityTrip[];
}

function Week({ items, beginAt, endAt, beginIndex, endIndex }: WeekProps) {
  const trips = items.slice(beginIndex, endIndex);
  return (
    <Stack col gap={3}>
      <h3>
        {dayjs(beginAt).format("ll")} &mdash; {dayjs(endAt).format("ll")}
      </h3>
      {trips.map((a, i) => (
        <React.Fragment key={a.id}>
          <Trip trip={a} />
          {i < trips.length - 1 && <hr className="mx-3" />}
        </React.Fragment>
      ))}
    </Stack>
  );
}

function Trip({ trip }: { trip: MobilityTrip }) {
  const { marshalToUrl } = useUrlMarshal();
  const { id, vehicleType, provider, beganAt, charge } = trip;
  return (
    <DivLink to={withQuery([`/trip/:id`, { id }], { trip: marshalToUrl(trip) })}>
      <Stack row className="justify-content-between">
        <Stack row gap={3}>
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
            <div className="color-text-muted">{dayjs(beganAt).format("MMM D, LT")}</div>
          </Stack>
        </Stack>
        <Stack row center gap={3}>
          <Money>{charge?.customerCost}</Money>
          <Icon icon="right" />
        </Stack>
      </Stack>
    </DivLink>
  );
}
