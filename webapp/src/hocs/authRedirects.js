import Redirect from "../shared/react/Redirect";
import useLoginRedirectLink from "../shared/react/useLoginRedirectLink";
import { useUser } from "../state/useUser";
import React from "react";
import { useLocation } from "react-router-dom";

export const redirectUnless = (to, test) => redirect(to, test);

const redirectUnlessUnauthed = (to, test) =>
  redirect(to, test, (setRedirectLink, pathname) => {
    setRedirectLink(pathname);
  });

function redirect(to, test, callback) {
  return (Wrapped) => {
    return (props) => {
      const userCtx = useUser();
      const { pathname } = useLocation();
      const { setRedirectLink } = useLoginRedirectLink();

      if (userCtx.userLoading) {
        return null;
      }

      if (test(userCtx)) {
        return <Wrapped {...props} />;
      }
      // We are unauthenticated at this point
      if (callback) {
        callback(setRedirectLink, pathname);
      }
      return <Redirect to={to} />;
    };
  };
}

export const redirectIfAuthed = redirectUnless(
  "/dashboard",
  ({ userUnauthed }) => userUnauthed
);

export const redirectIfUnauthed = redirectUnlessUnauthed(
  "/",
  ({ userAuthed }) => userAuthed
);

export const redirectIfBoarded = redirectUnless(
  "/dashboard",
  ({ user }) => !user.onboarded
);

export const redirectIfUnboarded = redirectUnless(
  "/onboarding",
  ({ user }) => user.onboarded
);
