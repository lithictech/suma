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
import Stack from "react-bootstrap/Stack";

const LocationInstructionsAlert = () => {
  const [userAgent, setUserAgent] = React.useState({});
  const [linkKey, setLinkKey] = React.useState("");
  const [icon, setIcon] = React.useState("");
  const [language] = useCurrentLanguage();
  React.useEffect(() => {
    if (!isEmpty(userAgent)) {
      return;
    }
    api
      .getUserAgent()
      .then(api.pickData)
      .then((ua) => {
        // get the second word in case for "Microsoft Edge"
        const browser = ua.device.toLowerCase().split(" ")[1] || ua.device.toLowerCase();
        if (ua.isIos) {
          setLinkKey("ios");
          setIcon("bi-apple");
        } else if (ua.isAndroid) {
          setLinkKey(`android`);
          setIcon("bi-android");
        } else if (supportedBrowsers.includes(browser)) {
          setLinkKey(browser);
          setIcon(`bi-browser-${browser}`);
        }
        setUserAgent(ua);
      });
  }, [userAgent]);
  const locationInstructionsMissing = !linkKey && !isEmpty(userAgent);
  return (
    <Alert variant="warning" className="m-0 fs-6">
      <i className="bi bi-exclamation-triangle-fill"></i> {t("errors:denied_geolocation")}
      {locationInstructionsMissing && (
        <p className="mt-2 mb-0">{md("mobility:location_instructions_missing")}</p>
      )}
      {linkKey && (
        <>
          <p className="mt-2">
            <i className="me-1 bi bi-arrow-clockwise"></i>
            {md("mobility:reload_after_instructions")}
          </p>
          <Stack direction="horizontal" className="justify-content-center">
            <ExternalLink
              component={Button}
              href={externalLinks[linkKey](language)}
              variant="outline-primary"
              className="h-100"
              style={{ minWidth: "33%" }}
            >
              <i className={clsx("me-1", icon && `bi ${icon}`)}></i>
              {t("mobility:activate_location_warning")}
            </ExternalLink>
          </Stack>
        </>
      )}
    </Alert>
  );
};

export default LocationInstructionsAlert;

const supportedBrowsers = ["safari", "chrome", "firefox", "edge"];
