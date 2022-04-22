import api from "../../api";
import MapBuilder from "../../modules/mapBuilder";
import { extractErrorCode, useError } from "../../state/useError";
import { useUser } from "../../state/useUser";
import FormError from "../FormError";
import ReservationCard from "./ReservationCard";
import TripCard from "./TripCard";
import React from "react";
import { Card } from "react-bootstrap";

const Map = () => {
  const mapRef = React.useRef();
  const { user } = useUser();
  const [selectedMapVehicle, setSelectedMapVehicle] = React.useState(null);
  const [loadedVehicle, setLoadedVehicle] = React.useState(null);
  const [ongoingTrip, setOngoingTrip] = React.useState(user.ongoingTrip);
  const [reserveError, setReserveError] = useError();
  const [error, setError] = useError();
  const [hasInit, setHasInit] = React.useState(null);

  const handleReserve = React.useCallback(
    (vehicle) => {
      api
        .beginMobilityTrip({
          providerId: vehicle.vendorService.id,
          vehicleId: vehicle.vehicleId,
          rateId: vehicle.rate.id,
        })
        .then((r) => {
          setOngoingTrip(r.data);
          hasInit.beginTrip(ongoingTrip);
        })
        .catch((e) => setError(extractErrorCode(e)));
    },
    [hasInit, ongoingTrip, setError]
  );

  const handleVehicleClick = React.useCallback(
    (mapVehicle) => {
      setError(null);
      setReserveError(null);
      setSelectedMapVehicle(mapVehicle);
      setLoadedVehicle(null);
      if (mapVehicle) {
        const { loc, providerId, disambiguator, type } = mapVehicle;
        api
          .getMobilityVehicle({ loc, providerId, disambiguator, type })
          .then((r) => setLoadedVehicle(r.data))
          .catch((e) => {
            setSelectedMapVehicle(null);
            setLoadedVehicle(null);
            setError(extractErrorCode(e));
          });
      }
    },
    [setError, setReserveError]
  );

  const handleEndTrip = () => setOngoingTrip(null);

  React.useEffect(() => {
    if (!mapRef.current) {
      return;
    }
    if (!hasInit) {
      const map = new MapBuilder(mapRef);
      map.init().run({ onVehicleClick: handleVehicleClick }).loadOngoingTrip(ongoingTrip);
      setHasInit(map);
    }
  }, [hasInit, ongoingTrip, handleVehicleClick]);

  return (
    <div className="position-relative">
      <div ref={mapRef} />
      {ongoingTrip ? (
        <TripCard trip={ongoingTrip} onEndTrip={handleEndTrip} />
      ) : (
        <ReservationCard
          active={Boolean(selectedMapVehicle)}
          loading={selectedMapVehicle && !loadedVehicle}
          vehicle={loadedVehicle}
          onReserve={handleReserve}
          reserveError={reserveError}
        />
      )}
      {error && (
        <Card className="reserve">
          <Card.Body>
            <FormError error={error} />
          </Card.Body>
        </Card>
      )}
    </div>
  );
};

export default Map;
