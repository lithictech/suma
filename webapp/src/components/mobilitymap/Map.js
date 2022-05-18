import api from "../../api";
import MapBuilder from "../../modules/mapBuilder";
import { extractErrorCode, useError } from "../../state/useError";
import { useUser } from "../../state/useUser";
import FormError from "../FormError";
import InstructionsModal from "./InstructionsModal";
import ReservationCard from "./ReservationCard";
import TripCard from "./TripCard";
import i18next from "i18next";
import React from "react";
import Alert from "react-bootstrap/Alert";
import Card from "react-bootstrap/Card";

const Map = () => {
  const mapRef = React.useRef();
  const { user } = useUser();
  const [loadedMap, setLoadedMap] = React.useState(null);
  const [selectedMapVehicle, setSelectedMapVehicle] = React.useState(null);
  const [loadedVehicle, setLoadedVehicle] = React.useState(null);
  const [lastMarkerLocation, setLastMarkerLocation] = React.useState(null);
  const [ongoingTrip, setOngoingTrip] = React.useState(user.ongoingTrip);
  const [reserveError, setReserveError] = useError();
  const [error, setError] = useError();

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

  const handleGetLastLocation = React.useCallback(
    (lastLocation) => setLastMarkerLocation(lastLocation),
    []
  );
  const handleGetLocationError = React.useCallback(() => {
    setError(
      <Alert variant="warning" className="m-0">
        <i className="bi bi-exclamation-triangle-fill"></i>{" "}
        {i18next.t("denied_geolocation", { ns: "errors" })}
        <InstructionsModal />
      </Alert>
    );
  }, [setError]);

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
          loadedMap.beginTrip({
            onGetLocation: handleGetLastLocation,
            onGetLocationError: handleGetLocationError,
          });
        })
        .catch((e) => setReserveError(extractErrorCode(e)));
    },
    [loadedMap, handleGetLastLocation, handleGetLocationError, setReserveError]
  );

  const handleStopTrip = () => loadedMap.endTrip({ onVehicleClick: handleVehicleClick });

  const handleCloseTrip = () => {
    setSelectedMapVehicle(null);
    setOngoingTrip(null);
  };

  React.useEffect(() => {
    if (!mapRef.current) {
      return;
    }
    if (!loadedMap) {
      const map = new MapBuilder(mapRef).init();
      if (ongoingTrip) {
        map.beginTrip({
          onGetLocation: handleGetLastLocation,
          onGetLocationError: handleGetLocationError,
        });
      } else {
        map.loadScooters({ onVehicleClick: handleVehicleClick });
      }
      setLoadedMap(map);
    }
  }, [
    loadedMap,
    ongoingTrip,
    handleVehicleClick,
    handleGetLastLocation,
    handleGetLocationError,
  ]);

  return (
    <div className="position-relative">
      <div ref={mapRef} />
      {ongoingTrip && !error ? (
        <TripCard
          trip={ongoingTrip}
          onCloseTrip={handleCloseTrip}
          onStopTrip={handleStopTrip}
          lastLocation={lastMarkerLocation}
        />
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
        <Card className="mobility-overlay-card">
          <Card.Body>
            <FormError error={error} noMargin component="div" />
          </Card.Body>
        </Card>
      )}
    </div>
  );
};

export default Map;
