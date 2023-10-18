import api from "../api";
import React from "react";

export const UserContext = React.createContext();
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

  React.useLayoutEffect(() => {
    api
      .getCurrentUser()
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
