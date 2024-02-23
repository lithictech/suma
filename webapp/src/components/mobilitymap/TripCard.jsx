import api from "../../api";
import { md, t } from "../../localization";
import { dayjs } from "../../modules/dayConfig";
import { extractErrorCode, useError } from "../../state/useError";
import useUser from "../../state/useUser";
import FormError from "../FormError";
import PageLoader from "../PageLoader";
import CardOverlay from "./CardOverlay";
import TransactionCard from "./TransactionCard";
import React from "react";
import Button from "react-bootstrap/Button";
import Card from "react-bootstrap/Card";

const TripCard = ({ active, trip, onCloseTrip, onEndTrip, lastLocation }) => {
  const { handleUpdateCurrentMember } = useUser();
  const [endTrip, setEndTrip] = React.useState(null);
  const [error, setError] = useError();
  if (!active) {
    return null;
  }
  if (!endTrip && !lastLocation) {
    return (
      <CardOverlay>
        <PageLoader />
      </CardOverlay>
    );
  }
  const handleEndTrip = () => {
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
        <TransactionCard endTrip={endTrip} error={error} onCloseTrip={handleCloseTrip} />
      )}
      {trip && !endTrip && lastLocation && (
        <CardOverlay>
          <Card.Title className="mb-2">{trip.provider.name}</Card.Title>
          <Card.Text className="text-muted">
            {t("mobility:trip_started_at", {
              at: dayjs(trip.beganAt).format("LT"),
            })}
          </Card.Text>
          <FormError error={error} />
          <Button
            size="sm"
            variant="outline-danger"
            className="w-100"
            onClick={handleEndTrip}
          >
            {md("mobility:end_trip")}
          </Button>
        </CardOverlay>
      )}
    </>
  );
};

export default TripCard;
