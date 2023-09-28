import api from "../../api";
import { md, t } from "../../localization";
import { useCurrentLanguage } from "../../localization/currentLanguage";
import externalLinks from "../../modules/externalLinks";
import useMountEffect from "../../shared/react/useMountEffect";
import useToggle from "../../shared/react/useToggle";
import ExternalLink from "../ExternalLink";
import SumaButton from "../SumaButton";
import clsx from "clsx";
import isEmpty from "lodash/isEmpty";
import React from "react";
import Alert from "react-bootstrap/Alert";

const LocationInstructionsAlert = () => {
  const [buttonProperties, setButtonProperties] = React.useState([]);
  const isLoading = useToggle(true);
  const [language] = useCurrentLanguage();
  useMountEffect(() => {
    api
      .getUserAgent()
      .then(api.pickData)
      .then((ua) => {
        setButtonProperties(supportedBrowserAndPlatform(ua));
        isLoading.turnOff();
      });
  });
  return (
    <Alert variant="warning" className="m-0 fs-6">
      <i className="bi bi-exclamation-triangle-fill"></i> {t("errors:denied_geolocation")}
      {!isEmpty(buttonProperties) && (
        <>
          <p className="mt-2">
            <i className="me-1 bi bi-arrow-clockwise"></i>
            {md("mobility:reload_after_instructions")}
          </p>
          {buttonProperties.map(({ key, icon, label }) => (
            <SumaButton
              key={key}
              href={externalLinks[key](language)}
              as={ExternalLink}
              className="mt-2"
            >
              <i className={clsx("me-1", icon)}></i>
              {label}
            </SumaButton>
          ))}
        </>
      )}
      {isLoading.isOff && isEmpty(buttonProperties) && (
        <p className="mt-2 mb-0">{md("mobility:location_instructions_missing")}</p>
      )}
    </Alert>
  );
};

export default LocationInstructionsAlert;

/**
 * Takes the user agent returns the supported browser and platform objects
 * The objects return key, icon and label properties. The key is used to get
 * the matching link from the externalLinks object. The icon represents a
 * Bootstrap icon className.
 *
 * Some browsers and platforms will have the same links but it is okay.
 *
 * Only the found browser and/or platform returned.
 *
 * @param ua The user agent to analyze device, platform and other data
 * @returns []
 */
function supportedBrowserAndPlatform(ua) {
  // get the second word in case for "Microsoft Edge"
  const browser = ua.device.toLowerCase().split(" ")[1] || ua.device.toLowerCase();
  // get the first word in case for "ios (iPad)"
  const platform = ua.platform.toLowerCase().split(" ")[0] || ua.platform.toLowerCase();
  const result = [];
  if (supportedBrowsers.includes(browser)) {
    result.push({
      key: browser,
      icon: `bi bi-browser-${browser}`,
      label: t("mobility:activate_device", { device: browser }),
    });
  }
  if (supportedPlatforms.includes(platform)) {
    if (platform === "macos" || ua.isIos) {
      result.push({
        key: "ios",
        icon: "bi bi-apple",
        label: t("mobility:activate_device", { device: platform }),
      });
    } else {
      result.push({
        key: platform,
        icon: `bi bi-${platform}`,
        label: t("mobility:activate_device", { device: platform }),
      });
    }
  }
  return result;
}

const supportedBrowsers = ["chrome", "firefox", "edge"];
const supportedPlatforms = ["macos", "ios", "windows", "android"];
