import api from "../../api";
import { t } from "../../localization";
import MapBuilder from "../../modules/mapBuilder";
import { extractErrorCode, useError } from "../../state/useError";
import { useUser } from "../../state/useUser";
import FormError from "../FormError";
import CardOverlay from "./CardOverlay";
import InstructionsModal from "./InstructionsModal";
import ReservationCard from "./ReservationCard";
import TripCard from "./TripCard";
import React from "react";
import { Link } from "react-router-dom";

const Map = () => {
  const mapRef = React.useRef();
  const { user, handleUpdateCurrentMember } = useUser();
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
  const handleGetLocationError = React.useCallback(
    () => setError(<InstructionsModal />),
    [setError]
  );

  const handleReserve = React.useCallback(
    (vehicle) => {
      api
        .beginMobilityTrip({
          providerId: vehicle.vendorService.id,
          vehicleId: vehicle.vehicleId,
          rateId: vehicle.rate.id,
        })
        .tap(handleUpdateCurrentMember)
        .then((r) => {
          setOngoingTrip(r.data);
          loadedMap.beginTrip();
        })
        .catch((e) => setReserveError(extractErrorCode(e)));
    },
    [handleUpdateCurrentMember, loadedMap, setReserveError]
  );

  const handleEndTrip = () => {
    loadedMap.loadScooters({ onVehicleClick: handleVehicleClick });
  };

  const handleCloseTrip = () => {
    setSelectedMapVehicle(null);
    setOngoingTrip(null);
  };

  React.useEffect(() => {
    if (!mapRef.current) {
      return;
    }
    if (!loadedMap) {
      const map = new MapBuilder(mapRef).init().startTrackingLocation({
        onGetLocation: handleGetLastLocation,
        onGetLocationError: handleGetLocationError,
      });
      if (ongoingTrip) {
        map.beginTrip();
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

  React.useEffect(() => {
    return () => {
      if (loadedMap) {
        loadedMap.unmount();
      }
    };
  }, [loadedMap]);

  return (
    <div className="position-relative">
      <div ref={mapRef} />
      <ReservationCard
        active={Boolean(selectedMapVehicle) && !ongoingTrip && !error}
        loading={selectedMapVehicle && !loadedVehicle}
        vehicle={loadedVehicle}
        onReserve={handleReserve}
        reserveError={reserveError}
        lastLocation={lastMarkerLocation}
      />
      <TripCard
        active={ongoingTrip && !error}
        trip={ongoingTrip}
        onCloseTrip={handleCloseTrip}
        onEndTrip={handleEndTrip}
        lastLocation={lastMarkerLocation}
      />
      {error && (
        <CardOverlay>
          <FormError error={error} noMargin component="div" />
          {user.readOnlyReason && (
            <Link to="/funding">{t("common:add_money_to_account")}</Link>
          )}
        </CardOverlay>
      )}
    </div>
  );
};

export default Map;
