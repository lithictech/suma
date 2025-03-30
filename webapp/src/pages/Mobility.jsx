import api from "../api";
import mobilityHeaderImage from "../assets/images/onboarding-mobility.jpg";
import FeaturePageHeader from "../components/FeaturePageHeader";
import { MdLink } from "../components/SumaMarkdown";
import WaitingList from "../components/WaitingList";
import Map from "../components/mobilitymap/Map";
import config from "../config";
import { imageAltT, t } from "../localization";
import { useError } from "../state/useError";
import clsx from "clsx";
import React from "react";

export default function Mobility() {
  if (!config.featureMobility) {
    return (
      <FeaturePageHeader
        imgSrc={mobilityHeaderImage}
        imgAlt={imageAltT("person_riding_scooter")}
      >
        <WaitingList
          title={t("mobility:title")}
          text={t("mobility:intro")}
          survey={{
            topic: "mobility_waitlist",
            questions: [],
          }}
        />
      </FeaturePageHeader>
    );
  }
  return <MobilityImpl />;
}

function MobilityImpl() {
  const [locationPermissionsError, setLocationPermissionsError] = useError("");
  const handleLocationPermissionsDenied = React.useCallback(() => {
    api
      .getUserAgent()
      .then((r) => {
        const instructionsUrl = getLocationPermissionsInstructionsUrl(r.data);
        if (!instructionsUrl) {
          throw new Error("unhandled user agent");
        }
        const opts = { context: "instructions", instructionsUrl: instructionsUrl };
        const localizedError = t(
          "mobility:location_permissions_denied_instructions",
          opts
        );
        setLocationPermissionsError(localizedError);
      })
      .catch(() => {
        setLocationPermissionsError(t("mobility:location_permissions_denied"));
      });
  }, [setLocationPermissionsError]);

  return (
    <div className="position-relative">
      <Map onLocationPermissionsDenied={handleLocationPermissionsDenied} />
      <Drawer className={locationPermissionsError && "bg-warning text-links-dark"}>
        {locationPermissionsError ||
          t(
            "mobility:intro",
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
          )}
      </Drawer>
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

function Drawer({ children, className }) {
  return <div className={clsx("mobility-drawer", className)}>{children}</div>;
}
