import api from "../api";
import mobilityHeaderImage from "../assets/images/onboarding-mobility.jpg";
import LayoutContainer from "../components/LayoutContainer";
import { MdLink } from "../components/SumaMarkdown";
import WaitingListPage from "../components/WaitingListPage";
import Map from "../components/mobilitymap/Map";
import config from "../config";
import { md, mdx, t } from "../localization";
import { useError } from "../state/useError";
import React from "react";
import Alert from "react-bootstrap/Alert";

export default function Mobility() {
  const [locationPermissionsError, setLocationPermissionsError] = useError(null);
  const introMd = mdx("mobility:intro", {
    overrides: {
      a: { component: MdLink },
      p: {
        props: {
          className: "text-secondary",
        },
      },
    },
  });
  const handleLocationPermissionsDenied = React.useCallback(() => {
    api.getUserAgent().then((r) => {
      let instructionsUrl = getLocationPermissionsInstructionsUrl(r.data);
      let localizedError = t("mobility:location_permissions_denied");
      if (instructionsUrl) {
        const opts = { context: "instructions", instructionsUrl: instructionsUrl };
        localizedError = md("mobility:location_permissions_denied", opts);
      }
      setLocationPermissionsError(localizedError);
    });
  }, [setLocationPermissionsError]);

  return config.featureMobility ? (
    <>
      <LayoutContainer top gutters>
        <h5>{t("mobility:title")}</h5>
        {introMd}
        {locationPermissionsError && (
          <Alert variant="warning">{locationPermissionsError}</Alert>
        )}
      </LayoutContainer>
      <Map onLocationPermissionsDenied={() => handleLocationPermissionsDenied()} />
    </>
  ) : (
    <div className="pb-4">
      <WaitingListPage
        feature="mobility"
        imgSrc={mobilityHeaderImage}
        imgAlt="Scooter Mobility"
        title={t("mobility:title")}
        text={introMd}
      />
    </div>
  );
}

/**
 * Returns browser location permissions instructions url if found or null.
 * @param browser User agent
 * @returns {string|null}
 */
function getLocationPermissionsInstructionsUrl(browser) {
  const device = browser.device.toLowerCase();
  let url = null;
  if (!browser || device === "Unknown") {
    return url;
  }
  // Using chrome in ios/android/desktop
  if (device === "chrome") {
    if (browser.isIos) {
      url =
        "https://support.google.com/chrome/answer/142065?hl=en&co=GENIE.Platform%3DiOS";
    } else if (browser.isAndroid) {
      url =
        "https://support.google.com/chrome/answer/142065?hl=en&co=GENIE.Platform%3DAndroid";
    } else {
      url =
        "https://support.google.com/chrome/answer/142065?hl=en&co=GENIE.Platform%3DDesktop";
    }
    return url;
  }
  // Using ios/safari, android, firefox device browsers
  if (browser.isIos || device === "safari") {
    url =
      "https://support.apple.com/guide/personal-safety/manage-location-services-settings-ips9bf20ad2f/web";
  } else if (browser.isAndroid) {
    url = "https://support.google.com/accounts/answer/6179507?hl=en";
  } else if (device === "firefox") {
    url =
      "https://support.mozilla.org/en-US/kb/does-firefox-share-my-location-websites#w_how-do-i-undo-a-permission-granted-to-a-site";
  }
  return url;
}
