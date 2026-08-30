import api from "../../api";
import { t } from "../../localization";
import { dayjs } from "../../modules/dayConfig";
import { AppError, extractAppErrorAny } from "../../modules/feedback.ts";
import useUser from "../../state/useUser";
import Button from "../../ui/Button";
import FormFeedback from "../../ui/FormFeedback";
import DrawerContents from "./DrawerContents";
import DrawerContentsLoading from "./DrawerContentsLoading.tsx";
import DrawerContentsPostTrip from "./DrawerContentsPostTrip.tsx";
import DrawerTitle from "./DrawerTitle";
import React from "react";

export interface MapLocation {
  latlng: { lat: number; lng: number };
}

interface TripProps {
  trip: MobilityTrip;
  onCloseTrip: () => void;
  onEndTrip: () => void;
  lastLocation: MapLocation;
}

export default function DrawerContentsOngoingTrip({
  trip,
  onCloseTrip,
  onEndTrip,
  lastLocation,
}: TripProps) {
  const { handleUpdateCurrentMember } = useUser();
  const [endTrip, setEndTrip] = React.useState<MobilityTrip | null>(null);
  const [error, setError] = React.useState<AppError | null>();
  if (!endTrip && !lastLocation) {
    return <DrawerContentsLoading />;
  }
  const handleEndTrip = () => {
    setError(null);
    api
      .endMobilityTrip({
        lat: lastLocation.latlng.lat,
        lng: lastLocation.latlng.lng,
      })
      .tap(handleUpdateCurrentMember)
      .then((r) => {
        onEndTrip();
        setEndTrip(r.data);
      })
      .catch((e) => setError(extractAppErrorAny(e)));
  };
  const handleCloseTrip = () => {
    onCloseTrip();
    setEndTrip(null);
  };
  return (
    <>
      {endTrip && (
        <DrawerContentsPostTrip
          endTrip={endTrip}
          error={error}
          onCloseTrip={handleCloseTrip}
        />
      )}
      {trip && !endTrip && lastLocation && (
        <DrawerContents>
          <DrawerTitle>{trip.provider.name}</DrawerTitle>
          <p className="text-muted">
            {t("mobility.trip_started_at", {
              at: dayjs(trip.beganAt).format("LT"),
            })}
          </p>
          <FormFeedback feedback={error} />
          <Button size="sm" variant="outline" className="w-100" onClick={handleEndTrip}>
            {t("mobility.end_trip")}
          </Button>
        </DrawerContents>
      )}
    </>
  );
}
