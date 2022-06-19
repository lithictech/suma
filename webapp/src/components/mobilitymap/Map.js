import api from "../../api";
import MapBuilder from "../../modules/mapBuilder";
import { extractErrorCode, useError } from "../../state/useError";
import { useUser } from "../../state/useUser";
import FormError from "../FormError";
import CardOverlay from "./CardOverlay";
import InstructionsModal from "./InstructionsModal";
import ReservationCard from "./ReservationCard";
import TripCard from "./TripCard";
import i18next from "i18next";
import React from "react";
import Alert from "react-bootstrap/Alert";
import { Link } from "react-router-dom";

const Map = () => {
  const mapRef = React.useRef();
  const { user, handleUpdateCurrentMember } = useUser();
  const [loadedMap, setLoadedMap] = React.useState(null);
  const [selectedMapVehicle, setSelectedMapVehicle] = React.useState(null);
  const [loadedVehicle, setLoadedVehicle] = React.useState(null);
  const [lastMarkerLocation, setLastMarkerLocation] = React.useState(null);
  const [activeTrip, setActiveTrip] = React.useState(Boolean(user.ongoingTrip) || false);
  const [ongoingTrip, setOngoingTrip] = React.useState(user.ongoingTrip);
  const [reserveError, setReserveError] = useError();
  const [error, setError] = useError();

  const handleVehicleClick = React.useCallback(
    (mapVehicle) => {
      setError(null);
      setReserveError(null);
      setSelectedMapVehicle(mapVehicle);
      setLoadedVehicle(null);
      if (user.readOnlyMode) {
        setError(extractErrorCode(user.readOnlyReason));
        return;
      }
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
    [user, setError, setReserveError]
  );

  const handleGetLastLocation = React.useCallback(
    (lastLocation) => setLastMarkerLocation(lastLocation),
    []
  );
  const handleGetLocationError = React.useCallback(() => {
    setError(
      <Alert variant="warning" className="m-0">
        <i className="bi bi-exclamation-triangle-fill"></i>{" "}
        {i18next.t("errors:denied_geolocation")}
        <InstructionsModal />
      </Alert>
    );
  }, [setError]);

  const handleReserve = React.useCallback(
    (vehicle) => {
      setActiveTrip(true);
      api
        .beginMobilityTrip({
          providerId: vehicle.vendorService.id,
          vehicleId: vehicle.vehicleId,
          rateId: vehicle.rate.id,
        })
        .tap(handleUpdateCurrentMember)
        .then((r) => {
          setOngoingTrip(r.data);
          loadedMap.beginTrip({
            onGetLocation: handleGetLastLocation,
            onGetLocationError: handleGetLocationError,
          });
        })
        .catch((e) => setReserveError(extractErrorCode(e)));
    },
    [
      handleUpdateCurrentMember,
      loadedMap,
      handleGetLastLocation,
      handleGetLocationError,
      setReserveError,
    ]
  );

  const handleStopTrip = () => loadedMap.endTrip({ onVehicleClick: handleVehicleClick });

  const handleCloseTrip = () => {
    setSelectedMapVehicle(null);
    setActiveTrip(null);
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
      <ReservationCard
        active={Boolean(selectedMapVehicle) && !ongoingTrip && !error}
        loading={selectedMapVehicle && !loadedVehicle}
        vehicle={loadedVehicle}
        onReserve={handleReserve}
        reserveError={reserveError}
      />
      <TripCard
        active={activeTrip && !error}
        trip={ongoingTrip}
        onCloseTrip={handleCloseTrip}
        onStopTrip={handleStopTrip}
        lastLocation={lastMarkerLocation}
      />
      {error && (
        <CardOverlay>
          <FormError error={error} noMargin component="div" />
          {user.readOnlyReason && (
            <Link to="/funding">{i18next.t("common:add_money_to_account")}</Link>
          )}
        </CardOverlay>
      )}
    </div>
  );
};

export default Map;
