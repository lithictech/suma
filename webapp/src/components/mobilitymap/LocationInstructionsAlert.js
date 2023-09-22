import api from "../../api";
import { md, t } from "../../localization";
import { useCurrentLanguage } from "../../localization/currentLanguage";
import externalLinks from "../../modules/externalLinks";
import ExternalLink from "../ExternalLink";
import clsx from "clsx";
import isEmpty from "lodash/isEmpty";
import React from "react";
import Alert from "react-bootstrap/Alert";
import Button from "react-bootstrap/Button";

const LocationInstructionsAlert = () => {
  const [browser, setBrowser] = React.useState({});
  const [linkKey, setLinkKey] = React.useState("");
  const [icon, setIcon] = React.useState("");
  const [language] = useCurrentLanguage();
  React.useEffect(() => {
    if (!isEmpty(browser)) {
      return;
    }
    api
      .getUserAgent()
      .then(api.pickData)
      .then((browser) => {
        setBrowser(browser);
        // get the second word in case for "Microsoft Edge"
        const device =
          browser.device.toLowerCase().split(" ")[1] || browser.device.toLowerCase();
        if (device === "unknown") {
          return;
        }
        if (browser.isIos) {
          setLinkKey("ios");
          setIcon("bi-apple");
          return;
        }
        if (browser.isAndroid) {
          setLinkKey("android");
          setIcon("bi-android");
          return;
        }
        const supportedBrowsers = ["safari", "chrome", "firefox", "edge"];
        if (supportedBrowsers.includes(device)) {
          setLinkKey(device);
          setIcon(`bi-browser-${device}`);
        }
      });
  }, [browser]);
  return (
    <Alert variant="warning" className="m-0">
      <i className="bi bi-exclamation-triangle-fill"></i> {t("errors:denied_geolocation")}
      {linkKey && (
        <>
          <p className="mt-2">
            <i className="me-1 bi bi-arrow-clockwise"></i>
            {md("mobility:reload_after_instructions")}
          </p>
          <ExternalLink
            component={Button}
            href={externalLinks[linkKey](language)}
            variant="outline-primary"
          >
            <i className={clsx("me-1", icon && `bi ${icon}`)}></i>
            {t(`mobility:location_instructions_btn`, { device: linkKey })}
          </ExternalLink>
        </>
      )}
    </Alert>
  );
};

export default LocationInstructionsAlert;
