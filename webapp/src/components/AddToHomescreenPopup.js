import React from "react";
import Button from "react-bootstrap/Button";

export default function AddToHomescreenPopup() {
  const [beforeInstallPromptEvent, setBeforeInstallPromptEvent] = React.useState(
    getBeforeInstallPromptEvent()
  );
  const [isAppInstalled, setIsAppInstalled] = React.useState(false);

  // function isStandalone() {
  //   // check IOS usage
  //   const isStandalone = window.matchMedia("(display-mode: standalone)").matches;
  //   // check if already using TWA
  //   const isTrustedWebActivities = document.referrer.startsWith("android-app://");
  //   if (!navigator.standalone || !isStandalone || isTrustedWebActivities) {
  //     return false;
  //   }
  //   return true;
  // }

  function handleAddToHomescreenPrompt() {
    if (!beforeInstallPromptEvent) {
      return;
    }
    return beforeInstallPromptEvent
      .prompt()
      .then(() => beforeInstallPromptEvent.userChoice)
      .then((choiceResult) => {
        if (choiceResult.outcome === "accepted") {
          console.log("user accepted the A2HS prompt");
          setIsAppInstalled(true);
        } else {
          console.log("user dismissed the A2HS prompt");
        }
        setBeforeInstallPromptEvent(null);
      })
      .catch((err) => {
        console.log(err.message);
      });
  }

  function getBeforeInstallPromptEvent() {
    if ("onbeforeinstallprompt" in window) {
      window.addEventListener("beforeinstallprompt", (event) => {
        // Prevent early prompt display
        event.preventDefault();
        return event;
      });
    }
    console.log("Event not found or set.");
    return null;
  }

  const initNavigatorEventHandlers = React.useCallback(() => {
    // TODO: Check navigator session . id to return; if prompt was already used (installed app)
    // this can be done by storing in localstorage
    if ("onappinstalled" in window) {
      window.addEventListener("appinstalled", () => {
        console.log("A2HS installed");
        setIsAppInstalled(true);
        // TODO: Add condition to return if app is already installed
      });
    }
    if ("serviceWorker" in navigator) {
      const serviceWorkerPath = `${process.env.PUBLIC_URL}/add-to-homescreen-service-worker.js`;
      navigator.serviceWorker.register(serviceWorkerPath).then((reg) => {
        // TODO: set/save id to localstorage?
        console.log("Registration succeeded. Scope is " + reg.scope, reg);
      });
    }
  }, []);

  React.useEffect(() => {
    initNavigatorEventHandlers();
  }, [initNavigatorEventHandlers]);

  return (
    <>
      {isAppInstalled ? (
        <p>App was installed!</p>
      ) : (
        <p>App has not been installed on this device.</p>
      )}
      {beforeInstallPromptEvent}
      <Button onClick={() => handleAddToHomescreenPrompt()}>Add to homescreen</Button>
    </>
  );
}
