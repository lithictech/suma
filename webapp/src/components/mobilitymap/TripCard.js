import api from "../../api";
import { dayjs } from "../../modules/dayConfig";
import { extractErrorCode, useError } from "../../state/useError";
import { useUser } from "../../state/useUser";
import FormError from "../FormError";
import PageLoader from "../PageLoader";
import CardOverlay from "./CardOverlay";
import TransactionCard from "./TransactionCard";
import i18next from "i18next";
import React from "react";
import Button from "react-bootstrap/Button";

const TripCard = ({ active, trip, onCloseTrip, onStopTrip, lastLocation }) => {
  const { handleUpdateCurrentMember } = useUser();
  const [endTrip, setEndTrip] = React.useState(null);
  const [error, setError] = useError();
  if (!active) {
    return null;
  }
  if (!endTrip && !lastLocation) {
    return (
      <CardOverlay>
        <PageLoader relative />
      </CardOverlay>
    );
  }
  const handleEndTrip = () => {
    const { lat, lng } = lastLocation.latlng;
    api
      .endMobilityTrip({
        lat: lat,
        lng: lng,
      })
      .tap(handleUpdateCurrentMember)
      .then((r) => {
        onStopTrip();
        setEndTrip(r.data);
      })
      .catch((e) => setError(extractErrorCode(e)));
  };
  const handleCloseTrip = () => onCloseTrip();
  return (
    <>
      {endTrip && (
        <TransactionCard endTrip={endTrip} error={error} onCloseTrip={handleCloseTrip} />
      )}
      {lastLocation && !endTrip && (
        <CardOverlay>
          <h6>{trip.provider.name}</h6>
          <p>
            {i18next.t("mobility:trip_started_at", {
              at: dayjs(trip.beganAt).format("LT"),
            })}
          </p>
          <FormError error={error} />
          <Button size="sm" variant="primary" className="w-100" onClick={handleEndTrip}>
            {i18next.t("mobility:end_trip")}
          </Button>
        </CardOverlay>
      )}
    </>
  );
};

export default TripCard;
