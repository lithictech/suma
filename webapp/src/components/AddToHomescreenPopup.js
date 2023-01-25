import React from "react";
import Button from "react-bootstrap/Button";

export default function AddToHomescreenPopup() {
  const [beforeInstallPromptEvent, setBeforeInstallPromptEvent] = React.useState(null);
  const [isAppInstalled, setIsAppInstalled] = React.useState(false);

  function isStandalone() {
    // check IOS usage
    const isStandalone = window.matchMedia("(display-mode: standalone)").matches;
    // check if already using TWA
    const isTrustedWebActivities = document.referrer.startsWith("android-app://");
    if (!navigator.standalone || !isStandalone || isTrustedWebActivities) {
      return false;
    }
    return true;
  }

  function handleAddToHomescreenPrompt() {
    // if (!isStandalone() || !beforeInstallPromptEvent) {
    //   return;
    // }
    console.log("Beforeinstallpront event: ", beforeInstallPromptEvent);
    return beforeInstallPromptEvent
      .prompt()
      .then(function () {
        // Wait for the member to respond to the prompt
        return beforeInstallPromptEvent.userChoice;
      })
      .then(function (choiceResult) {
        if (choiceResult.outcome === "accepted") {
          console.log("user accepted the A2HS prompt");
          setIsAppInstalled(true);
        } else {
          console.log("user dismissed the A2HS prompt");
        }
        setBeforeInstallPromptEvent(null);
      })
      .catch(function (err) {
        console.log(err.message);
        if (err.message.indexOf("The app is already installed") > -1) {
          console.log(err.message);
        } else {
          console.log(err);
        }
      });
  }
  const initNavigatorEventHandlers = React.useCallback(() => {
    // TODO: Check navigator session . id to return; if prompt was already used (installed app)
    // this can be done by storing in localstorage

    if ("onbeforeinstallprompt" in window) {
      window.addEventListener("beforeinstallprompt", (event) => {
        // Prevent early prompt display
        event.preventDefault();
        // event saved for later use with button
        setBeforeInstallPromptEvent(event);
        console.log(beforeInstallPromptEvent);
      });
    }
    if ("onappinstalled" in window) {
      window.addEventListener("appinstalled", (evt) => {
        console.log("A2HS installed");
        setIsAppInstalled(true);
      });
    }

    if ("serviceWorker" in navigator) {
      const serviceWorkerPath = `${process.env.PUBLIC_URL}/add-to-homescreen-service-worker.js`;
      // Scope path is strict, needs to end with a slash
      const scopePath =
        process.env.NODE_ENV !== "development" ? `${process.env.PUBLIC_URL}/` : "./";
      navigator.serviceWorker.register(serviceWorkerPath).then((register) => {
        console.log("Registration succeeded. Scope is " + register.scope);
      });
      // bypass manifest check
      setTimeout(function () {
        // we wait 1 sec until we execute this because sometimes the browser needs a little time to register the service worker
        navigator.serviceWorker.getRegistration().then((reg) => {
          console.log("navigator is in service! Registration: ", reg);
        });
      }, 1000);
    }
  }, [beforeInstallPromptEvent]);

  React.useEffect(() => {
    initNavigatorEventHandlers();
  }, [initNavigatorEventHandlers]);

  return (
    <>
      {isAppInstalled && <p>App was installed after accepting!</p>}
      <Button onClick={() => handleAddToHomescreenPrompt()}>Add to homescreen</Button>
    </>
  );
}
