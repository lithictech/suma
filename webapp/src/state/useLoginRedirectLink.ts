import useSessionStorageState from "../shared/react/useSessionStorageState";
import React from "react";

const REDIRECT_LINK_SESSION_KEY = "sumaNextUrl";

export default function useLoginRedirectLink() {
  const [redirectLink, setRedirectLinkInner] = useSessionStorageState<string>(
    REDIRECT_LINK_SESSION_KEY
  );
  const setRedirectLink = React.useCallback(
    (x: string) => {
      if (x !== redirectLink) {
        setRedirectLinkInner(x);
      }
    },
    [redirectLink, setRedirectLinkInner]
  );
  const clearRedirectLink = React.useCallback(() => {
    setRedirectLink("");
  }, [setRedirectLink]);
  const value = React.useMemo(
    () => ({ redirectLink, setRedirectLink, clearRedirectLink }),
    [clearRedirectLink, redirectLink, setRedirectLink]
  );
  return value;
}
