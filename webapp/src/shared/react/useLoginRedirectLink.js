import { sessionStorageCache } from "../localStorageHelper";
import useSessionStorageState from "./useSessionStorageState";
import isEmpty from "lodash/isEmpty";
import React from "react";

const REDIRECT_LINK_SESSION_KEY = "sumaNextUrll";

export default function useLoginRedirectLink() {
  const [link, setInnerLink] = useSessionStorageState(REDIRECT_LINK_SESSION_KEY);

  const setLink = React.useCallback(
    (redirectLink) => {
      if (!isEmpty(link)) {
        return;
      }
      setInnerLink(redirectLink);
    },
    [setInnerLink, link]
  );

  const value = React.useMemo(
    () => ({
      redirectLink: link,
      setRedirectLink: setLink,
      removeRedirectLink: () => sessionStorageCache.removeItem(REDIRECT_LINK_SESSION_KEY),
    }),
    [setLink, link]
  );
  return value;
}
