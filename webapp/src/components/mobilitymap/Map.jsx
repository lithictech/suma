import api from "../../api";
import config from "../../config";
import { md, t } from "../../localization";
import MapBuilder from "../../modules/mapBuilder";
import readOnlyReason from "../../modules/readOnlyReason";
import useMountEffect from "../../shared/react/useMountEffect";
import { extractErrorCode, useError } from "../../state/useError";
import useGlobalViewState from "../../state/useGlobalViewState";
import useUser from "../../state/useUser";
import FormError from "../FormError";
import RLink from "../RLink";
import CardOverlay from "./CardOverlay";
import ReservationCard from "./ReservationCard";
import TripCard from "./TripCard";
import React from "react";
import Button from "react-bootstrap/Button";

export default function Map() {
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
      if (!mapVehicle) {
        return;
      }
      if (config.featureMobilityRestricted) {
        setError(md("errors:mobility_coming_soon"));
        return;
      }
      const { loc, provider, disambiguator, type } = mapVehicle;
      if (user.readOnlyMode) {
        const canStillRide =
          user.readOnlyReason === "read_only_zero_balance" && provider.zeroBalanceOk;
        if (!canStillRide) {
          setError(extractErrorCode(user.readOnlyReason));
          return;
        }
      }
      api
        .getMobilityVehicle({ loc, providerId: provider.id, disambiguator, type })
        .then((r) => setLoadedVehicle(r.data))
        .catch((e) => {
          setSelectedMapVehicle(null);
          setLoadedVehicle(null);
          setError(extractErrorCode(e));
        });
    },
    [user, setError, setReserveError]
  );

  const handleVehicleRemove = React.useCallback(() => setSelectedMapVehicle(null), []);
  const handleLocationFound = React.useCallback(
    (lastLocation) => setLastMarkerLocation(lastLocation),
    []
  );
  const handleLocationError = React.useCallback(
    (map, { cachedLocation }) => {
      // If finding the location fails, geolocate the IP instead.
      // Don't locate if we have a cached location though, just use
      // where the map was last left.
      if (cachedLocation) {
        return;
      }
      api
        .geolocateIp()
        .then((r) => {
          const { lat, lng } = r.data;
          map.centerLocation({ lat, lng, targetZoom: 14 });
        })
        .catch((e) => {
          console.error("Error fetching ip:", e);
          setError("unhandled_error");
        });
    },
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
    loadedMap
      ?.setVehicleEventHandlers({
        onClick: handleVehicleClick,
        onSelectedRemoved: handleVehicleRemove,
      })
      .loadScooters();
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
    // We only want this evaluated on load. We handle it imperatively otherwise.
    if (ongoingTrip) {
      map.beginTrip();
    } else {
      // Need these so loadScooters works.
      // We handle any changes to the event handlers with their own useEffect later on.
      map
        .setVehicleEventHandlers({
          onClick: handleVehicleClick,
          onSelectedRemoved: handleVehicleRemove,
        })
        .loadScooters();
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
        reserveError={reserveError}
        onReserve={handleReserve}
      />
      <TripCard
        active={ongoingTrip && !error}
        lastLocation={lastMarkerLocation}
        trip={ongoingTrip}
        onCloseTrip={handleCloseTrip}
        onEndTrip={handleEndTrip}
      />
      {error && (
        <CardOverlay>
          <FormError error={error} noMargin component="div" />
          {!config.featureMobilityRestricted &&
            readOnlyReason(user, "read_only_zero_balance") && (
              <div className="text-center mt-2">
                <Button variant="outline-success" to="/funding" size="sm" as={RLink}>
                  {t("payments:add_funds")}
                </Button>
              </div>
            )}
        </CardOverlay>
      )}
    </div>
  );
}
