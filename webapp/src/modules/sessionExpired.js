import { localStorageCache } from "../shared/localStorageHelper";
import { storeLoginRedirectLink } from "../state/useLoginRedirectLink";

/**
 * Local storage key for the cached current user. See UserProvider.
 */
export const USER_STORAGE_KEY = "sumauser";

/**
 * Query param (and value) added to /start when the user is sent there
 * because their session ended, so the page can explain what happened.
 */
export const SESSION_EXPIRED_PARAM = "session";
export const SESSION_EXPIRED_VALUE = "expired";

/**
 * Routes that can be used without being signed in.
 * A 401 while on these pages is not a session that ended during an activity,
 * so we do not interrupt the user.
 */
const PUBLIC_PATHS = [
  "/start",
  "/one-time-password",
  "/regain-account-access",
  "/contact-list",
  "/partner-signup",
  "/privacy-policy",
  "/privacy-policy-content",
  "/terms-of-use",
  "/glossary",
  "/preferences-public",
  "/error",
  "/styleguide",
];

export function isPublicPath(path) {
  if (!path || path === "/") {
    return true;
  }
  return PUBLIC_PATHS.some((p) => path === p || path.startsWith(p + "/"));
}

function basePath() {
  return (import.meta.env.BASE_URL || "/").replace(/\/+$/, "");
}

/**
 * Return the path of the current page relative to the router basename,
 * like '/food' for '/app/food'.
 */
function currentRoutePath() {
  const base = basePath();
  let path = window.location.pathname;
  if (base && path.startsWith(base)) {
    path = path.slice(base.length);
  }
  return path || "/";
}

let handling = false;

/**
 * Call when the API tells us the user is no longer authenticated (HTTP 401).
 *
 * If the user was signed in and is using a page that requires it,
 * remember where they were (using the same storage as the login redirect link),
 * forget the cached user, and send them to sign in again with a notice.
 * After signing in, they are returned to the stored location (see OneTimePassword),
 * and forms using useFormDraft restore what was typed (WCAG 2.2.5 Re-authenticating).
 *
 * @returns {boolean} True if the user is being sent to sign in.
 */
export function handleSessionExpired() {
  if (handling) {
    return true;
  }
  const hadUser = Boolean(localStorageCache.getItem(USER_STORAGE_KEY, null));
  if (!hadUser) {
    return false;
  }
  const path = currentRoutePath();
  if (isPublicPath(path)) {
    return false;
  }
  handling = true;
  storeLoginRedirectLink(path + window.location.search);
  localStorageCache.removeItem(USER_STORAGE_KEY);
  // Use a full page load so all in-memory state for the signed-in user is dropped.
  window.location.assign(
    `${basePath()}/start?${SESSION_EXPIRED_PARAM}=${SESSION_EXPIRED_VALUE}`
  );
  return true;
}
