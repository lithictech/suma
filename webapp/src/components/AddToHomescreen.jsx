import sumaLogo from "../assets/images/suma-logo-word-512.png";
import config from "../config";
import { t } from "../localization";
import useLocalStorageState from "../shared/react/useLocalStorageState";
import useToggle from "../shared/react/useToggle";
import PageLoader from "./PageLoader";
import React from "react";
import Alert from "react-bootstrap/Alert";
import Button from "react-bootstrap/Button";

/**
 * We depend on installPromptEvent and service worker registration
 * to render this A2HS component. Therefore, it will render null if
 * they are not set, the device is not compatible or shouldPrompt is
 * false.
 *
 * installPromptEvent renders on the initial page load and within
 * full production app URL scope (must include slash at end of URL).
 *
 * @returns {JSX.Element}
 */
export default function AddToHomescreen() {
  // Bump the 'should prompt to install' number if we want to ask everyone to install again.
  // In the future we could do something like storing a dismissal date and expiring.
  const currentPromptVersion = 1;
  const [shouldPrompt, setShouldPrompt] = useLocalStorageState(
    `should-prompt-to-install-${currentPromptVersion}`,
    true
  );
  const [hasRegistration, setHasRegistration] = React.useState(false);
  const loading = useToggle(false);
  const addToHomescreenButtonRef = React.useRef(null);
  const [installPromptEvent, setInstallPromptEvent] = React.useState(null);

  const installPrompt = React.useCallback(() => {
    loading.turnOn();
    return installPromptEvent
      .prompt()
      .then(() => installPromptEvent.userChoice)
      .then((result) => {
        if (result.outcome === "accepted") {
          setShouldPrompt(false);
          return;
        }
        setInstallPromptEvent(null);
      })
      .catch((err) => {
        if (err.message.indexOf("The app is already installed") > -1) {
          setShouldPrompt(false);
          return;
        }
        setInstallPromptEvent(null);
        console.error("Error prompting to install app:", err);
      })
      .finally(loading.turnOff);
  }, [loading, setShouldPrompt, installPromptEvent]);

  const handleBeforeInstallPrompt = React.useCallback((event) => {
    // Prevent early prompt display
    event.preventDefault();
    setInstallPromptEvent(event);
  }, []);

  React.useEffect(
    function initEventHandlers() {
      if (!isCompatible || !shouldPrompt) {
        return;
      }

      if (!installPromptEvent && "onbeforeinstallprompt" in window) {
        window.addEventListener("beforeinstallprompt", handleBeforeInstallPrompt);
      }
      if (!hasRegistration) {
        setTimeout(() => {
          navigator.serviceWorker
            .getRegistration(config.apiHost || undefined)
            .then((sw) => {
              if (sw) {
                setHasRegistration(true);
              }
            })
            .catch(() => setHasRegistration(false));
        }, 1000);
      }

      if (!addToHomescreenButtonRef.current) {
        return;
      }
      addToHomescreenButtonRef.current.addEventListener("click", () => installPrompt());
      if ("onappinstalled" in window) {
        window.addEventListener("appinstalled", () => setShouldPrompt(false));
      }

      return () => {
        window.removeEventListener("beforeinstallprompt", handleBeforeInstallPrompt);
      };
    },
    [
      hasRegistration,
      installPrompt,
      installPromptEvent,
      setShouldPrompt,
      shouldPrompt,
      handleBeforeInstallPrompt,
    ]
  );

  if (!shouldPrompt || !isCompatible || !installPromptEvent || !hasRegistration) {
    return null;
  }
  if (loading.isOn) {
    return <PageLoader />;
  }
  return (
    <Alert
      variant="primary"
      className="mt-4 mb-2"
      show={shouldPrompt}
      onClose={() => setShouldPrompt(false)}
      dismissible
    >
      <Alert.Heading>
        <img
          src={sumaLogo}
          alt={t("common:suma_logo")}
          className="me-2"
          style={{ width: 50 }}
        />
        {t("common:add_to_homescreen")}
      </Alert.Heading>
      <p>{t("common:add_to_homescreen_intro")}</p>
      <div className="d-flex justify-content-end">
        <Button ref={addToHomescreenButtonRef} variant="primary">
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
  const isTablet = /ipad/i.test(window.navigator.userAgent);
  return isPhone || isTablet;
})();
