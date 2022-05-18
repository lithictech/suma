import api from "../../api";
import { extractErrorCode, useError } from "../../state/useError";
import FormError from "../FormError";
import TransactionCard from "./TransactionCard";
import React from "react";
import { Button, Card } from "react-bootstrap";

const TripCard = ({ trip, onCloseTrip, onStopTrip, lastLocation }) => {
  const [endTrip, setEndTrip] = React.useState(null);
  const [error, setError] = useError();
  if (!trip) {
    return null;
  }
  const handleEndTrip = () => {
    const { lat, lng } = lastLocation.latlng;
    api
      .endMobilityTrip({
        lat: lat,
        lng: lng,
      })
      .then((r) => {
        onStopTrip();
        setEndTrip(r.data);
      })
      .catch((e) => setError(extractErrorCode(e)));
  };
  const handleCloseTrip = () => onCloseTrip();

  return (
    <>
      {endTrip ? (
        <TransactionCard endTrip={endTrip} error={error} onCloseTrip={handleCloseTrip} />
      ) : (
        <Card className="mobility-overlay-card">
          <Card.Body>
            <Card.Text className="text-muted">Scooter {trip.id}</Card.Text>
            {/* TODO: add error handling */}
            <FormError error={error} />
            <Button size="sm" variant="primary" className="w-100" onClick={handleEndTrip}>
              End Trip
            </Button>
          </Card.Body>
        </Card>
      )}
    </>
  );
};

export default TripCard;
