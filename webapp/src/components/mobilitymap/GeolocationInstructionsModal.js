import api from "../../api";
import { t } from "../../localization";
import { useCurrentLanguage } from "../../localization/currentLanguage";
import FormButtons from "../FormButtons";
import clsx from "clsx";
import { capitalize } from "lodash";
import isEmpty from "lodash/isEmpty";
import React from "react";
import Alert from "react-bootstrap/Alert";

const GeolocationInstructionsModal = () => {
  const [browser, setBrowser] = React.useState({});
  const [linkKey, setLinkKey] = React.useState("");
  const [platform, setPlatform] = React.useState("");
  const [version, setVersion] = React.useState("");
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
        // get the second word in case for "Microsft Edge"
        const device = browser.device.toLowerCase().split(" ")[1];
        if (device === "unknown") {
          return;
        }
        if (browser.isIos) {
          setLinkKey("ios");
          setIcon("bi-apple");
          return;
        }
        if (browser.isAndroid) {
          setLinkKey("chrome");
          setIcon("bi-android");
          setPlatform("Android");
          setVersion(browser.platformVersion);
          return;
        }
        const supportedBrowsers = ["safari", "chrome", "firefox", "edge"];
        const supportedBrowserFound = supportedBrowsers.includes(device);
        console.log(supportedBrowserFound);
        if (supportedBrowserFound) {
          setLinkKey(device);
          setIcon(`bi-browser-${device}`);
          setPlatform(browser.platform);
          if (device === "chrome") {
            setPlatform("Desktop");
          }
        }
      });
  }, [browser]);

  return (
    <>
      <Alert variant="warning" className="m-0">
        <i className="bi bi-exclamation-triangle-fill"></i>{" "}
        {t("errors:denied_geolocation")}
        {linkKey && (
          <>
            <p className="mb-0">
              <b>Refresh</b> this page after you are done following instructions.
            </p>
            <FormButtons
              variant="outline-primary"
              primaryProps={{
                children: (
                  <>
                    <i className={clsx("me-1", icon && `bi ${icon}`)}></i>
                    {t(`location_instructions_links:label`, {
                      device: capitalize(linkKey),
                    })}
                  </>
                ),
                href: t(`location_instructions_links:${linkKey}`, {
                  lang: language,
                  platform,
                }),
              }}
            />
          </>
        )}
      </Alert>
    </>
  );
};

export default GeolocationInstructionsModal;
