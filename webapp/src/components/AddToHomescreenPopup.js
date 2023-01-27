import sumaLogo from "../assets/images/suma-logo-word-512.png";
import { t } from "../localization";
import { localStorageCache } from "../shared/localStorageHelper";
import useLocalStorageState from "../shared/react/useLocalStorageState";
import React from "react";
import { Alert } from "react-bootstrap";
import Button from "react-bootstrap/Button";

let canPromptCache = localStorageCache.getItem("canPromptA2HS", true);

export default function AddToHomescreenPopup() {
  const [canPrompt, setCanPrompt] = useLocalStorageState("canPromptA2HS", true);
  const addToHomescreenButton = React.useRef(null);

  const initNavigatorEventHandlers = React.useCallback(() => {
    if (canPrompt) {
      window.addEventListener("beforeinstallprompt", (event) => {
        // Prevent early prompt display
        event.preventDefault();
        addToHomescreenButton.current.addEventListener("click", () => {
          event
            .prompt()
            .then(() => event.userChoice)
            .then(() => {
              setCanPrompt(false);
              canPromptCache = false;
              event = null;
            })
            .catch((err) => {
              if (err.message.indexOf("The app is already installed") > -1) {
                setCanPrompt(false);
                canPromptCache = false;
              }
              return err;
            });
        });
      });
    }
    if ("onappinstalled" in window) {
      window.addEventListener("appinstalled", () => {
        setCanPrompt(false);
        canPromptCache = false;
      });
    }
  }, [canPrompt, setCanPrompt]);
  React.useEffect(initNavigatorEventHandlers, [initNavigatorEventHandlers]);

  if (!canPrompt || !isCompatible()) {
    return null;
  }
  return (
    <Alert
      variant="primary"
      show={canPrompt}
      onClose={() => {
        setCanPrompt(false);
        canPromptCache = false;
      }}
      dismissible
    >
      <Alert.Heading>
        <img src={sumaLogo} alt="MySuma Logo" className="me-2" style={{ width: 50 }} />
        {t("common:add_to_homescreen")}
      </Alert.Heading>
      <p>{t("common:add_to_homescreen_intro")}</p>
      <div className="d-flex justify-content-end">
        <Button ref={addToHomescreenButton} variant="primary">
          <i className="bi bi-box-arrow-down me-1"></i>
          {t("common:install_suma")}
        </Button>
      </div>
    </Alert>
  );
}

const isCompatible = () => {
  const userAgent = window.navigator.userAgent;
  const isIDevice = /iphone|ipod|ipad/i.test(userAgent);
  const isSamsung = /Samsung/i.test(userAgent);
  const isChromium = "onbeforeinstallprompt" in window;
  const isMobileSafari =
    isIDevice && userAgent.indexOf("Safari") > -1 && userAgent.indexOf("CriOS") < 0;
  const isWebAppIOS = window.navigator.standalone === true;
  const isWebAppChrome = window.matchMedia("(display-mode: standalone)").matches;
  const isStandalone = isWebAppIOS || isWebAppChrome;
  const isTrustedWebActivities = document.referrer.startsWith("android-app://");
  // some web and mobile browsers are not supported
  // https://developer.mozilla.org/en-US/docs/Web/API/BeforeInstallPromptEvent
  if (isStandalone || isTrustedWebActivities || isMobileSafari) {
    return false;
  }
  // check serviceworker support
  if (!("serviceWorker" in navigator)) {
    return false;
  }
  return isChromium || isSamsung;
};
