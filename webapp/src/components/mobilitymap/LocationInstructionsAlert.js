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
  const [userAgent, setUserAgent] = React.useState({});
  const isLoading = useToggle(true);
  const [language] = useCurrentLanguage();
  useMountEffect(() => {
    api
      .getUserAgent()
      .then(api.pickData)
      .then((ua) => {
        setUserAgent(ua);
        isLoading.turnOff();
      });
  });
  const { browser, platform, isApple, supportedBrowser, supportedPlatform } = userAgent;
  return (
    <Alert variant="warning" className="m-0 fs-6">
      <i className="bi bi-exclamation-triangle-fill"></i> {t("errors:denied_geolocation")}
      {(supportedBrowser || supportedPlatform) && (
        <p className="mt-2">
          <i className="me-1 bi bi-arrow-clockwise"></i>
          {md("mobility:reload_after_instructions")}
        </p>
      )}
      {supportedBrowser && (
        <SumaButton
          href={externalLinks[browser](language)}
          as={ExternalLink}
          className="mt-2"
        >
          <i className={clsx("me-1", `bi bi-browser-${browser}`)}></i>
          {t("mobility:activate_device", { device: browser })}
        </SumaButton>
      )}
      {supportedPlatform && (
        <SumaButton
          href={externalLinks[platform](language)}
          as={ExternalLink}
          className="mt-2"
        >
          <i className={clsx("me-1", `bi bi-${isApple ? "apple" : platform}`)}></i>
          {t("mobility:activate_device", { device: platform })}
        </SumaButton>
      )}
      {isLoading.isOff && isEmpty(userAgent) && (
        <p className="mt-2 mb-0">{md("mobility:location_instructions_missing")}</p>
      )}
    </Alert>
  );
};

export default LocationInstructionsAlert;
