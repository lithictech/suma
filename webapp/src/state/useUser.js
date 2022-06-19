import api from "../api";
import { localStorageCache } from "../shared/localStorageHelper";
import humps from "humps";
import _ from "lodash";
import React from "react";

export const UserContext = React.createContext();
/**
 * @returns {{user: User, setUser: function, userLoading: boolean, userError: object, userAuthed: boolean, userUnauthed: boolean}}
 */
export const useUser = () => React.useContext(UserContext);
export function UserProvider({ children }) {
  // Store the current user in the local storage cache.
  // Load from the cache optimistically; if we have a cached user,
  // use it immediately while we go and fetch from the backend.
  // This avoids blocking doing anything while we wait on the user,
  // which normally won't change in a meaningful way
  // (and when it does change, the app will react to its new state properly).
  const [user, setUserInner] = React.useState(
    localStorageCache.getItem(STORAGE_KEY, null)
  );
  const [userLoading, setUserLoading] = React.useState(!user);
  const [userError, setUserError] = React.useState(null);

  const setUser = React.useCallback((u) => {
    setUserInner(u);
    localStorageCache.setItem(STORAGE_KEY, u);
    setUserLoading(false);
    setUserError(null);
  }, []);

  const fetchUser = React.useCallback(() => {
    return api
      .getMe()
      .then(api.pickData)
      .then(setUser)
      .catch((e) => {
        setUserInner(null);
        localStorageCache.removeItem(STORAGE_KEY);
        setUserLoading(false);
        setUserError(e);
      });
  }, [setUser]);

  React.useEffect(() => {
    fetchUser().then(() => null);
  }, [fetchUser]);

  // See add_current_member_header for more info.
  const handleUpdateCurrentMember = React.useCallback(
    (response) => {
      const memberBase64 = _.get(response, ["headers", "suma-current-member"]);
      if (!memberBase64) {
        console.warn(
          "handleUpdateCurrentMember not used properly, response or header is malformed"
        );
        return;
      }
      const j = atob(memberBase64);
      const member = JSON.parse(j);
      setUser(humps.camelizeKeys(member));
    },
    [setUser]
  );

  return (
    <UserContext.Provider
      value={{
        user,
        setUser,
        userLoading,
        userError,
        userAuthed: Boolean(user),
        userUnauthed: !userLoading && !user,
        handleUpdateCurrentMember,
      }}
    >
      {children}
    </UserContext.Provider>
  );
}

const STORAGE_KEY = "sumauser";

/**
 * @typedef User
 * @property {boolean} ongoingTrip
 * @property {boolean} readOnlyMode
 * @property {string} readOnlyReason
 * @property {Array<object>} usablePaymentInstruments
 */
