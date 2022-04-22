import api from "../../api";
import { extractErrorCode, useError } from "../../state/useError";
import FormError from "../FormError";
import React from "react";
import { Button, Card } from "react-bootstrap";

const TripCard = ({ trip, onEndTrip }) => {
  const [endTrip, setEndTrip] = React.useState(null);
  const [error, setError] = useError();
  if (!trip) {
    return null;
  }
  const handleEndTrip = () => {
    const { beginLat, beginLng } = trip;
    api
      .endMobilityTrip({
        lat: beginLat,
        lng: beginLng,
      })
      .then((r) => setEndTrip(r.data))
      .catch((e) => setError(extractErrorCode(e)));
  };
  const handleCloseTrip = () => onEndTrip();

  return (
    <>
      {endTrip ? (
        <TransactionDisplay
          endTrip={endTrip}
          error={error}
          onCloseTrip={handleCloseTrip}
        />
      ) : (
        <Card className="reserve">
          <Card.Body>
            <Card.Text className="text-muted">Scooter {trip.id}</Card.Text>
            <FormError error={error} />
            <Button size="sm" variant="danger" onClick={handleEndTrip}>
              End Trip
            </Button>
          </Card.Body>
        </Card>
      )}
    </>
  );
};

export default TripCard;

// TODO: setup as component
const TransactionDisplay = ({ endTrip, onCloseTrip, error }) => {
  const { rate, provider, id } = endTrip;
  const handleClose = () => onCloseTrip();
  return (
    <Card className="reserve">
      <Card.Body>
        {/* TODO: localization */}
        <p>Your trip {id} has ended.</p>
        <p>Provider: {provider.vendorName}</p>
        <p>Rate:{rate.localizationKey}</p>
        <p>Total: $2</p>
        <FormError error={error} />
        <Button size="sm" variant="outline-success" onClick={handleClose}>
          Done
        </Button>
      </Card.Body>
    </Card>
  );
};
