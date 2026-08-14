import api from "../../api";
import config from "../../config";
import { t } from "../../localization";
import MapBuilder from "../../modules/mapBuilder";
import useMountEffect from "../../shared/react/useMountEffect";
import { extractErrorCode, useError } from "../../state/useError";
import useGlobalViewState from "../../state/useGlobalViewState";
import useUser from "../../state/useUser";
import FormError from "../FormError";
import { MdLink } from "../SumaMarkdown";
import Drawer from "./Drawer";
import DrawerContents from "./DrawerContents";
import DrawerTitle from "./DrawerTitle";
import MicromobilityRate from "./MicromobilityRate";
import PreTrip from "./PreTrip";
import Trip from "./Trip";
import React from "react";

export default function Map() {
  const { appNav, topNav } = useGlobalViewState();
  const mapRef = React.useRef<HTMLDivElement>(null);
  const { user, handleUpdateCurrentMember } = useUser();
  const [loadedMap, setLoadedMap] = React.useState<MapBuilder | null>(null);
  const [selectedMapVehicle, setSelectedMapVehicle] = React.useState<any>(null);
  const [loadedVehicle, setLoadedVehicle] = React.useState<any>(null);
  const [lastMarkerLocation, setLastMarkerLocation] = React.useState<any>(null);
  const [ongoingTrip, setOngoingTrip] = React.useState(user.ongoingTrip);
  const [reserveError, setReserveError] = useError();
  const [locationPermissionsError, setLocationPermissionsError] = useError("");
  const [error, setError] = useError();

  const handleVehicleClick = React.useCallback(
    (mapVehicle: any) => {
      setError(null);
      setReserveError(null);
      setSelectedMapVehicle(mapVehicle);
      setLoadedVehicle(null);
      if (!mapVehicle) {
        return;
      }
      if (config.featureMobilityRestricted) {
        setError(t("errors.mobility_coming_soon"));
        return;
      }
      const { loc, provider, disambiguator, type } = mapVehicle;
      if (provider.usageProhibitedReason) {
        setError(provider.usageProhibitedReason);
        return;
      }
      api
        .getMobilityVehicle({ loc, providerId: provider.id, disambiguator, type })
        .then((r: any) => setLoadedVehicle(r.data))
        .catch((e: any) => {
          setSelectedMapVehicle(null);
          setLoadedVehicle(null);
          setError(extractErrorCode(e));
        });
    },
    [setError, setReserveError]
  );

  const handleVehicleRemove = React.useCallback(() => setSelectedMapVehicle(null), []);
  const handleLocationFound = React.useCallback(
    (lastLocation: any) => setLastMarkerLocation(lastLocation),
    []
  );

  const handleLocationPermissionDeniedSetText = React.useCallback(() => {
    api
      .getUserAgent()
      .then((r: any) => {
        const instructionsUrl = getLocationPermissionsInstructionsUrl(r.data);
        if (!instructionsUrl) {
          throw new Error("unhandled user agent");
        }
        const opts = { context: "instructions", instructionsUrl: instructionsUrl };
        const localizedError = t(
          "mobility.location_permissions_denied_instructions",
          opts
        );
        setLocationPermissionsError(localizedError);
      })
      .catch(() => {
        setLocationPermissionsError(t("mobility.location_permissions_denied"));
      });
  }, [setLocationPermissionsError]);

  const handleLocationError = React.useCallback(
    (map: any, { cachedLocation }: { cachedLocation?: any }) => {
      handleLocationPermissionDeniedSetText();
      // If finding the location fails, geolocate the IP instead.
      // Don't locate if we have a cached location though, just use
      // where the map was last left.
      if (cachedLocation) {
        return;
      }
      api
        .geolocateIp()
        .then((r: any) => {
          const { lat, lng } = r.data;
          map.centerLocation({ lat, lng, targetZoom: 14 });
        })
        .catch((e: any) => {
          console.error("Error fetching ip:", e);
          setError("unhandled_error");
        });
    },
    [handleLocationPermissionDeniedSetText, setError]
  );

  const handleReserve = React.useCallback(
    (vehicle: any) => {
      api
        .beginMobilityTrip({
          providerId: vehicle.vendorService.id,
          vehicleId: vehicle.vehicleId,
          rateId: vehicle.rate.id,
        })
        .tap(handleUpdateCurrentMember)
        .then((r: any) => {
          setOngoingTrip(r.data);
          loadedMap!.beginTrip();
        })
        .catch((e: any) => setReserveError(extractErrorCode(e)));
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

  // On mount, load the map. It's very important that any dependencies (like onLocationFound, etc.)
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

  let drawerFooter = null;
  const drawerContent = (() => {
    if (error && !selectedMapVehicle) {
      return <FormError error={error} noMargin component="div" />;
    } else if (error) {
      const { provider } = selectedMapVehicle;
      return (
        <DrawerContents>
          <DrawerTitle>{provider.name}</DrawerTitle>
          <MicromobilityRate rate={provider.rate} />
          <FormError className="my-0" error={error} />
        </DrawerContents>
      );
    }
    if (ongoingTrip) {
      return (
        <Trip
          lastLocation={lastMarkerLocation}
          trip={ongoingTrip}
          onCloseTrip={handleCloseTrip}
          onEndTrip={handleEndTrip}
        />
      );
    }
    if (selectedMapVehicle) {
      if (loadedVehicle?.subsidyMatchPercentage > 0) {
        drawerFooter = (
          <div className="py-3 px-4 small text-bg-primary">
            {t("mobility.rate_additional_savings", {
              percentage: loadedVehicle.subsidyMatchPercentage,
            })}
          </div>
        );
      }
      return (
        <PreTrip
          loading={selectedMapVehicle && !loadedVehicle}
          vehicle={loadedVehicle}
          reserveError={reserveError}
          onReserve={handleReserve}
        />
      );
    }
    if (locationPermissionsError) {
      return locationPermissionsError;
    }
    return defaultDrawerContents();
  })();

  return (
    <div className="position-relative">
      <Drawer footer={drawerFooter}>{drawerContent}</Drawer>
      <div ref={mapRef} style={{ height: `calc(100vh - ${navsHeight}px` }} />
    </div>
  );
}

function defaultDrawerContents() {
  return t(
    "mobility.intro",
    {},
    {
      markdown: {
        overrides: {
          a: { component: MdLink },
          p: {
            props: {
              className: "text-secondary",
            },
          },
        },
      },
    }
  );
}

/**
 * Returns browser location permissions instructions url if found or null.
 */
function getLocationPermissionsInstructionsUrl(browser: any): string | null {
  const device = browser.device.toLowerCase();
  if (device === "chrome") {
    // Using chrome in ios/android/desktop
    if (browser.isIos) {
      return "https://support.google.com/chrome/answer/142065?hl=en&co=GENIE.Platform%3DiOS";
    } else if (browser.isAndroid) {
      return "https://support.google.com/chrome/answer/142065?hl=en&co=GENIE.Platform%3DAndroid";
    } else {
      return "https://support.google.com/chrome/answer/142065?hl=en&co=GENIE.Platform%3DDesktop";
    }
  } else if (browser.isIos || device === "safari") {
    // Using ios/safari, android, firefox device browsers
    return "https://support.apple.com/guide/personal-safety/manage-location-services-settings-ips9bf20ad2f/web";
  } else if (browser.isAndroid) {
    return "https://support.google.com/accounts/answer/6179507?hl=en";
  } else if (device === "firefox") {
    return "https://support.mozilla.org/en-US/kb/does-firefox-share-my-location-websites#w_how-do-i-undo-a-permission-granted-to-a-site";
  }
  return null;
}
