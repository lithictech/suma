import api from "../api";
import React from "react";

export const UserContext = React.createContext();
/**
 * @returns {{user: User, setUser: function, userLoading: boolean, userError: object, userAuthed: boolean, userUnauthed: boolean}}
 */
export const useUser = () => React.useContext(UserContext);
export function UserProvider({ children }) {
  const [user, setUserInner] = React.useState(null);
  const [userLoading, setUserLoading] = React.useState(true);
  const [userError, setUserError] = React.useState(null);

  function setUser(u) {
    setUserInner(u);
    setUserLoading(false);
    setUserError(null);
  }

  React.useEffect(() => {
    api
      .getMe()
      .then(api.pickData)
      .then(setUser)
      .catch((e) => {
        setUserInner(null);
        setUserLoading(false);
        setUserError(e);
      });
  }, []);

  return (
    <UserContext.Provider
      value={{
        user,
        setUser,
        userLoading,
        userError,
        userAuthed: Boolean(user),
        userUnauthed: !userLoading && !user,
      }}
    >
      {children}
    </UserContext.Provider>
  );
}

/**
 * @typedef User
 * @property {boolean} ongoingTrip
 * @property {boolean} readOnlyMode
 * @property {string} readOnlyReason
 * @property {Array<object>} usablePaymentInstruments
 */
