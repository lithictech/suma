import api from "../api";
import { base64decode } from "../modules/base64";
import { localStorageCache } from "../modules/localStorageHelper";
import { Logger } from "../modules/logger";
import { withSentry } from "../modules/sentry";
import humps from "humps";
import get from "lodash/get";
import React from "react";

const logger = new Logger("user");

type ScratchData = Record<string, any>;

export interface UserContextValue {
  user: CurrentMember | null;
  setUser: (u: CurrentMember | null) => void;
  scratchData: ScratchData;
  setScratchData: (r: ScratchData) => void;
  userLoading: boolean;
  userError: any;
  userAuthed: boolean;
  userUnauthed: boolean;
  handleUpdateCurrentMember: (response: any) => void;
  registrationSession: RegistrationLink | null;
}

export const UserContext = React.createContext<UserContextValue>({} as UserContextValue);

export default function UserProvider({ children }: { children: React.ReactNode }) {
  // Store the current user in the local storage cache.
  // Load from the cache optimistically; if we have a cached user,
  // use it immediately while we go and fetch from the backend.
  // This avoids blocking doing anything while we wait on the user,
  // which normally won't change in a meaningful way
  // (and when it does change, the app will react to its new state properly).
  const [user, setUserInner] = React.useState<CurrentMember | null>(
    localStorageCache.getItem(STORAGE_KEY, null)
  );
  const [userLoading, setUserLoading] = React.useState(!user);
  const [userError, setUserError] = React.useState<any>(null);

  const setUser = React.useCallback((u: CurrentMember | null) => {
    withSentry((sentry) => {
      const user = u ? { id: u.id, email: u.email, username: u.name } : null;
      sentry.setUser(user);
    });
    setUserInner(u);
    localStorageCache.setItem(STORAGE_KEY, u);
    setUserLoading(false);
    setUserError(null);
  }, []);

  // When GET /me 401s, set this value, and use it if the user is unauthed.
  const [regLinkFromError, setRegLinkFromError] = React.useState<RegistrationLink | null>(
    null
  );

  const fetchUser = React.useCallback(() => {
    return api
      .getMe()
      .then((r: any) => setUser(r.data))
      .catch((e: any) => {
        setUserInner(null);
        localStorageCache.removeItem(STORAGE_KEY);
        setUserLoading(false);
        setUserError(e);
        const camelErr = humps.camelizeKeys(e.response?.data?.error || {});
        setRegLinkFromError(camelErr.registrationLink);
      });
  }, [setUser]);

  React.useEffect(() => {
    fetchUser().then(() => null);
  }, [fetchUser]);

  // See add_current_member_header for more info.
  const handleUpdateCurrentMember = React.useCallback(
    (response: any) => {
      const memberBase64 = get(response, ["headers", "suma-current-member"]);
      if (!memberBase64) {
        logger.error(
          "handleUpdateCurrentMember not used properly, response or header is malformed"
        );
        return;
      }
      const j = base64decode(memberBase64);
      const member = JSON.parse(j);
      setUser(humps.camelizeKeys(member));
    },
    [setUser]
  );

  const registrationSession = React.useMemo(
    () => (user ? user.registrationLink : regLinkFromError),
    [regLinkFromError, user]
  );

  const [scratchData, setScratchData] = React.useState({} as ScratchData);

  const value = React.useMemo(
    () => ({
      user,
      setUser,
      scratchData,
      setScratchData,
      userLoading,
      userError,
      userAuthed: Boolean(user),
      userUnauthed: !userLoading && !user,
      handleUpdateCurrentMember,
      registrationSession,
    }),
    [
      handleUpdateCurrentMember,
      registrationSession,
      scratchData,
      setUser,
      user,
      userError,
      userLoading,
    ]
  );

  return <UserContext.Provider value={value}>{children}</UserContext.Provider>;
}

const STORAGE_KEY = "sumauser";
