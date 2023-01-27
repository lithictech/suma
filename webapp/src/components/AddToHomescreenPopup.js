import React from "react";
import Button from "react-bootstrap/Button";

export default function AddToHomescreenPopup() {
  const [isAppInstalled, setIsAppInstalled] = React.useState(false);
  const addToHomescreenButton = React.useRef(null);

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

  const initNavigatorEventHandlers = React.useCallback(() => {
    // TODO: Check navigator session . id to return; if prompt was already used (installed app)
    // this can be done by storing in localstorage

    if ("onbeforeinstallprompt" in window) {
      window.addEventListener("beforeinstallprompt", (event) => {
        // Prevent early prompt display
        event.preventDefault();
        addToHomescreenButton.current.addEventListener("click", () => {
          event
            .prompt()
            .then(() => event.userChoice)
            .then((choiceResult) => {
              if (choiceResult.outcome === "accepted") {
                console.log("user accepted the A2HS prompt");
                setIsAppInstalled(true);
              } else {
                console.log("user dismissed the A2HS prompt");
              }
            })
            .catch((err) => {
              console.log(err.message);
            });
        })
      });
    }
    if ("onappinstalled" in window) {
      window.addEventListener("appinstalled", () => {
        console.log("A2HS installed");
        setIsAppInstalled(true);
      });
    }
  }, []);

  React.useEffect(initNavigatorEventHandlers, [initNavigatorEventHandlers]);

  return (
    <>
      {isAppInstalled ? (
        <p>App was installed!</p>
      ) : (
        <p>App has not been installed on this device.</p>
      )}
      <Button ref={addToHomescreenButton}>Add to homescreen</Button>
    </>
  );
}
