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
  const [locationPermissionsError, setLocationPermissionsError] = useError("");
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
    api
      .getUserAgent()
      .then((r) => {
        const instructionsUrl = getLocationPermissionsInstructionsUrl(r.data);
        if (!instructionsUrl) {
          throw new Error("unhandled user agent");
        }
        const opts = { context: "instructions", instructionsUrl: instructionsUrl };
        const localizedError = md("mobility:location_permissions_denied", opts);
        setLocationPermissionsError(localizedError);
      })
      .catch(() => {
        setLocationPermissionsError(t("mobility:location_permissions_denied"));
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
      <Map onLocationPermissionsDenied={handleLocationPermissionsDenied} />
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
