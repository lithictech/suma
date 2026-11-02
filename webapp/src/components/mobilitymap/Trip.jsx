import api from "../../api";
import { t } from "../../localization";
import { dayjs } from "../../modules/dayConfig";
import { extractErrorCode, useError } from "../../state/useError";
import useUser from "../../state/useUser";
import FormError from "../FormError";
import DrawerContents from "./DrawerContents";
import DrawerLoading from "./DrawerLoading";
import DrawerTitle from "./DrawerTitle";
import PostTrip from "./PostTrip";
import React from "react";
import Button from "react-bootstrap/Button";

export default function Trip({ trip, onCloseTrip, onEndTrip, lastLocation }) {
  const { handleUpdateCurrentMember } = useUser();
  const [endTrip, setEndTrip] = React.useState(null);
  const [error, setError] = useError();
  if (!endTrip && !lastLocation) {
    return <DrawerLoading />;
  }
  const handleEndTrip = () => {
    setError("");
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
      .catch((e) => setError(extractErrorCode(e)));
  };
  const handleCloseTrip = () => {
    onCloseTrip();
    setEndTrip(null);
  };
  return (
    <>
      {endTrip && (
        <PostTrip endTrip={endTrip} error={error} onCloseTrip={handleCloseTrip} />
      )}
      {trip && !endTrip && lastLocation && (
        <DrawerContents>
          <DrawerTitle>{trip.provider.name}</DrawerTitle>
          <p className="text-muted">
            {t("mobility.trip_started_at", {
              at: dayjs(trip.beganAt).format("LT"),
            })}
          </p>
          <FormError error={error} />
          <Button
            size="sm"
            variant="outline-danger"
            className="w-100"
            onClick={handleEndTrip}
          >
            {t("mobility.end_trip")}
          </Button>
        </DrawerContents>
      )}
    </>
  );
}
