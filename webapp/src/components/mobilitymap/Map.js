import api from "../../api";
import MapBuilder from "../../modules/mapBuilder";
import { useUser } from "../../state/useUser";
import ReservationCard from "./ReservationCard";
import React from "react";
import { Button, Card } from "react-bootstrap";

const Map = () => {
  const mapRef = React.useRef();
  const { user } = useUser();
  const [selectedMapVehicle, setSelectedMapVehicle] = React.useState(null);
  const [loadedVehicle, setLoadedVehicle] = React.useState(null);
  const [ongoingTrip, setOngoingTrip] = React.useState(user.ongoingTrip);

  const handleReserve = React.useCallback((vehicle) => {
    api
      .beginMobilityTrip({
        providerId: vehicle.vendorService.id,
        vehicleId: vehicle.vehicleId,
        rateId: vehicle.rate.id,
      })
      .then((r) => setOngoingTrip(r.data))
      .catch((e) => console.error(e));
  }, []);

  const handleVehicleClick = React.useCallback((mapVehicle) => {
    setSelectedMapVehicle(mapVehicle);
    setLoadedVehicle(null);
    const { loc, providerId, disambiguator, type } = mapVehicle;
    api
      .getMobilityVehicle({ loc, providerId, disambiguator, type })
      .then((r) => setLoadedVehicle(r.data))
      .catch((e) => {
        console.error(e);
        // TODO: Handle error
      });
  }, []);

  React.useEffect(() => {
    if (!mapRef.current) {
      return;
    }
    new MapBuilder(mapRef).init({ onVehicleClick: handleVehicleClick });
  }, [handleVehicleClick]);

  return (
    <div className="position-relative">
      <div ref={mapRef} />
      {ongoingTrip ? (
        <TripCard trip={ongoingTrip} />
      ) : (
        <ReservationCard
          active={Boolean(selectedMapVehicle)}
          loading={selectedMapVehicle && !loadedVehicle}
          vehicle={loadedVehicle}
          onReserve={handleReserve}
        />
      )}
    </div>
  );
};

export default Map;

function TripCard({ trip, onEndTrip }) {
  return (
    <Card className="reserve">
      <Card.Body>
        <Card.Text className="text-muted">Trip {trip.id}</Card.Text>
        <Button size="sm" variant="outline-success" onClick={onEndTrip}>
          End Trip
        </Button>
      </Card.Body>
    </Card>
  );
}
