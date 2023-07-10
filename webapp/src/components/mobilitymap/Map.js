import api from "../../api";
import { t } from "../../localization";
import MapBuilder from "../../modules/mapBuilder";
import useMountEffect from "../../shared/react/useMountEffect";
import { extractErrorCode, useError } from "../../state/useError";
import { useGlobalViewState } from "../../state/useGlobalViewState";
import { useUser } from "../../state/useUser";
import FormError from "../FormError";
import CardOverlay from "./CardOverlay";
import GeolocationInstructionsModal from "./GeolocationInstructionsModal";
import ReservationCard from "./ReservationCard";
import TripCard from "./TripCard";
import React from "react";
import { Link } from "react-router-dom";

const Map = () => {
  const { appNav, topNav } = useGlobalViewState();
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

  const handleVehicleRemove = React.useCallback(() => setSelectedMapVehicle(null), []);
  const handleLocationFound = React.useCallback(
    (lastLocation) => setLastMarkerLocation(lastLocation),
    []
  );
  const handleLocationError = React.useCallback(
    () => setError(<GeolocationInstructionsModal />),
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

  const handleEndTrip = React.useCallback(() => {
    loadedMap?.loadScooters({
      onVehicleClick: handleVehicleClick,
      onVehicleRemove: handleVehicleRemove,
    });
  }, [handleVehicleClick, handleVehicleRemove, loadedMap]);

  const handleCloseTrip = React.useCallback(() => {
    setSelectedMapVehicle(null);
    setOngoingTrip(null);
  }, []);

  // On mount, load the map. It's very important that any dependencies (like onLocationFound, etc)
  // are constant callbacks (ie they have no or only constant dependencies).
  useMountEffect(() => {
    if (!mapRef.current) {
      return;
    }
    const map = new MapBuilder(mapRef.current).init().startTrackingLocation({
      onLocationFound: handleLocationFound,
      onLocationError: handleLocationError,
    });
    // Need these so loadScooters works.
    // We handle any changes to the event handlers with their own useEffect later on.
    map.setVehicleEventHandlers({
      onClick: handleVehicleClick,
      onSelectedRemoved: handleVehicleRemove,
    });
    // We only want this evaluated on load. We handle it imperatively otherwise.
    if (ongoingTrip) {
      map.beginTrip();
    } else {
      map.loadScooters();
    }
    setLoadedMap(map);
    return () => {
      map.unmount();
      setLoadedMap(null);
    };
  });

  // Whenever the vehciel event handlers change, update the map.
  React.useEffect(() => {
    if (!loadedMap) {
      return;
    }
    loadedMap.setVehicleEventHandlers({
      onClick: handleVehicleClick,
      onSelectedRemoved: handleVehicleRemove,
    });
  }, [handleVehicleClick, handleVehicleRemove, loadedMap]);

  const navsHeight = (topNav?.clientHeight || 0) + (appNav?.clientHeight || 0);

  return (
    <div className="position-relative">
      <div ref={mapRef} style={{ height: `calc(100vh - ${navsHeight}px` }} />
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
