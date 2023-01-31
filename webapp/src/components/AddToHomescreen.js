import sumaLogo from "../assets/images/suma-logo-word-512.png";
import config from "../config";
import { t } from "../localization";
import useLocalStorageState from "../shared/react/useLocalStorageState";
import useToggle from "../shared/react/useToggle";
import PageLoader from "./PageLoader";
import React from "react";
import { Alert } from "react-bootstrap";
import Button from "react-bootstrap/Button";

export default function AddToHomescreen() {
  // Bump the 'should prompt to install' number if we want to ask everyone to install again.
  // In the future we could do something like storing a dismissal date and expiring.
  const [shouldPrompt, setShouldPrompt] = useLocalStorageState(
    "should-prompt-to-install-0",
    true
  );
  const [hasRegistration, setHasRegistration] = React.useState(false);
  const loading = useToggle(false);
  const addToHomescreenButtonRef = React.useRef(null);

  const installPrompt = React.useCallback(
    (event) => {
      loading.turnOn();
      return event
        .prompt()
        .then(() => event.userChoice)
        .then((result) => {
          if (result.outcome === "accepted") {
            setShouldPrompt(false);
          }
        })
        .catch((err) => {
          if (err.message.indexOf("The app is already installed") > -1) {
            setShouldPrompt(false);
          } else {
            console.error("Error prompting to install app:", err);
          }
        })
        .finally(loading.turnOff);
    },
    [loading, setShouldPrompt]
  );

  React.useEffect(
    function initEventHandlers() {
      setTimeout(() => {
        navigator.serviceWorker
          .getRegistration(config.apiHost)
          .then((sw) => {
            if (sw) {
              setHasRegistration(true);
            }
          })
          .catch((_e) => setHasRegistration(false));
      }, 100);

      if (
        !isCompatible ||
        !shouldPrompt ||
        !hasRegistration ||
        !addToHomescreenButtonRef.current
      ) {
        return;
      }
      window.addEventListener("beforeinstallprompt", (event) => {
        // Prevent early prompt display
        event.preventDefault();
        addToHomescreenButtonRef.current.addEventListener("click", () =>
          installPrompt(event)
        );
      });
      if ("onappinstalled" in window) {
        window.addEventListener("appinstalled", () => setShouldPrompt(false));
      }
    },
    [hasRegistration, installPrompt, setShouldPrompt, shouldPrompt]
  );

  if (!shouldPrompt || !isCompatible || !hasRegistration) {
    return;
  }
  if (loading.isOn) {
    return <PageLoader relative="true" />;
  }
  return (
    <Alert
      variant="primary"
      show={shouldPrompt}
      onClose={() => setShouldPrompt(false)}
      dismissible
    >
      <Alert.Heading>
        <img src={sumaLogo} alt="MySuma Logo" className="me-2" style={{ width: 50 }} />
        {t("common:add_to_homescreen")}
      </Alert.Heading>
      <p>{t("common:add_to_homescreen_intro")}</p>
      <div className="d-flex justify-content-end">
        <Button ref={addToHomescreenButtonRef} variant="primary">
          <i className="bi bi-box-arrow-down me-1"></i>
          {t("common:install_suma")}
        </Button>
      </div>
    </Alert>
  );
}

const isCompatible = (() => {
  if (!("serviceWorker" in navigator)) {
    return false;
  }
  const supportsInstall = "onbeforeinstallprompt" in window;
  if (!supportsInstall) {
    return false;
  }
  const userAgent = window.navigator.userAgent;
  const isWebAppIOS = window.navigator.standalone === true;
  if (isWebAppIOS) {
    return false;
  }
  const isWebAppChrome = window.matchMedia("(display-mode: standalone)").matches;
  if (isWebAppChrome) {
    return false;
  }
  // https://developer.chrome.com/docs/android/trusted-web-activity/
  const isTrustedWebActivities = document.referrer.startsWith("android-app://");
  if (isTrustedWebActivities) {
    return false;
  }
  const isPhone = window.outerWidth < 700; // Good enough for us since we are mobile-only
  const isTablet = /ipad/i.test(userAgent);
  return isPhone || isTablet;
})();
