import Redirect from "../shared/react/Redirect";
import useLoginRedirectLink from "../state/useLoginRedirectLink";
import useUser from "../state/useUser";
import React from "react";
import { useLocation } from "react-router-dom";

function redirectUnless(to, test, options) {
  const { setRedirectLinkOnTestFalse } = options || {};
  return (Wrapped) => {
    return (props) => {
      const userCtx = useUser();
      const { pathname, search } = useLocation();
      const { setRedirectLink } = useLoginRedirectLink();

      if (userCtx.userLoading) {
        return null;
      }

      if (test(userCtx)) {
        return <Wrapped {...props} />;
      }
      if (setRedirectLinkOnTestFalse) {
        // Include the query, so pages that depend on it work when we come back.
        setRedirectLink(pathname + search);
      }
      return <Redirect to={to} />;
    };
  };
}

export const redirectIfAuthed = redirectUnless(
  "/dashboard",
  ({ userUnauthed }) => userUnauthed
);

export const redirectIfUnauthed = redirectUnless("/", ({ userAuthed }) => userAuthed, {
  setRedirectLinkOnTestFalse: true,
});

export const redirectIfBoarded = redirectUnless(
  "/dashboard",
  ({ user }) => !user.onboarded
);

export const redirectIfUnboarded = redirectUnless(
  "/onboarding",
  ({ user }) => user.onboarded
);
