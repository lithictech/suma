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
import DrawerContents from "./DrawerContents.jsx";
import DrawerTitle from "./DrawerTitle.jsx";
import MicromobilityRate from "./MicromobilityRate.jsx";
import PreTrip from "./PreTrip";
import Trip from "./Trip";
import React from "react";

export default function Map() {
  const { appNav, topNav } = useGlobalViewState();
  const mapRef = React.useRef();
  const drawerRef = React.useRef(null);
  const { user, handleUpdateCurrentMember } = useUser();
  const [loadedMap, setLoadedMap] = React.useState(null);
  const [selectedMapVehicle, setSelectedMapVehicle] = React.useState(null);
  const [loadedVehicle, setLoadedVehicle] = React.useState(null);
  const [lastMarkerLocation, setLastMarkerLocation] = React.useState(null);
  const [ongoingTrip, setOngoingTrip] = React.useState(user.ongoingTrip);
  const [reserveError, setReserveError] = useError();
  const [locationPermissionsError, setLocationPermissionsError] = useError("");
  const [error, setError] = useError();
  // True when focus should move into the drawer once its content has loaded.
  const [drawerFocusPending, setDrawerFocusPending] = React.useState(false);
  const [refreshStatus, setRefreshStatus] = React.useState("");

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
        .then((r) => setLoadedVehicle(r.data))
        .catch((e) => {
          setSelectedMapVehicle(null);
          setLoadedVehicle(null);
          setDrawerFocusPending(false);
          setError(extractErrorCode(e));
        });
    },
    [setError, setReserveError]
  );

  const handleVehicleRemove = React.useCallback(() => setSelectedMapVehicle(null), []);
  const handleLocationFound = React.useCallback(
    (lastLocation) => setLastMarkerLocation(lastLocation),
    []
  );

  const handleLocationPermissionDeniedSetText = React.useCallback(() => {
    api
      .getUserAgent()
      .then((r) => {
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
    (map, { cachedLocation }) => {
      handleLocationPermissionDeniedSetText();
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
    [handleLocationPermissionDeniedSetText, setError]
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
          // The button that had focus is replaced by the trip.
          setDrawerFocusPending(true);
          loadedMap.beginTrip();
        })
        .catch((e) => setReserveError(extractErrorCode(e)));
    },
    [handleUpdateCurrentMember, loadedMap, setReserveError]
  );

  const handleEndTrip = React.useCallback(() => {
    // The button that had focus is replaced by the trip summary.
    setDrawerFocusPending(true);
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
    setDrawerFocusPending(false);
    loadedMap?.releaseSelectedVehicle();
  }, [loadedMap]);

  // Pointer users close the vehicle drawer by clicking the map.
  // Let keyboard users close it with Escape (WCAG 2.1.3).
  const handleDrawerKeyDown = (e) => {
    if (e.key !== "Escape" || !selectedMapVehicle || ongoingTrip) {
      return;
    }
    // React events bubble out of portals, so ignore Escape from the confirmation modal.
    if (!drawerRef.current?.contains(e.target)) {
      return;
    }
    handleCloseDrawer();
  };

  const handleRefreshPausedChange = React.useCallback(
    (paused) =>
      setRefreshStatus(
        paused ? t("mobility.updates_paused") : t("mobility.updates_resumed")
      ),
    []
  );

  // On mount, load the map. It's very important that any dependencies (like onLocationFound, etc.)
  // are constant callbacks (ie they have no or only constant dependencies).
  useMountEffect(() => {
    if (!mapRef.current) {
      return;
    }
    const map = new MapBuilder(mapRef.current)
      .init()
      .setRefreshEventHandlers({ onPausedChange: handleRefreshPausedChange })
      .startTrackingLocation({
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

  // Selecting a vehicle on the map opens it in the drawer, which comes before
  // the map in the page. Move focus to the drawer title (or the drawer, if there is no title)
  // once the content has loaded, so keyboard and screen reader users land on it (WCAG 2.1.3, 2.4.3).
  // The content loads in child components, so watch the drawer rather than our own renders.
  React.useEffect(() => {
    const drawer = drawerRef.current;
    if (!drawerFocusPending || !drawer) {
      return;
    }
    const focusWhenLoaded = () => {
      if (drawer.querySelector("[data-drawer-loading]")) {
        return false;
      }
      const target = drawer.querySelector(".mobility-drawer-title") || drawer;
      target.focus({ preventScroll: true });
      setDrawerFocusPending(false);
      return true;
    };
    if (focusWhenLoaded()) {
      return;
    }
    const observer = new MutationObserver(() => {
      if (focusWhenLoaded()) {
        observer.disconnect();
      }
    });
    observer.observe(drawer, { childList: true, subtree: true });
    return () => observer.disconnect();
  }, [drawerFocusPending]);

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
 * @param {object} browser Backend response
 * @returns {string|null}
 */
function getLocationPermissionsInstructionsUrl(browser) {
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
