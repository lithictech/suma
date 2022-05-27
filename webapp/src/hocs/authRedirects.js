import Redirect from "../shared/react/Redirect";
import { useUser } from "../state/useUser";
import React from "react";

export function redirectUnless(to, test) {
  return (Wrapped) => {
    return (props) => {
      const userCtx = useUser();
      if (userCtx.userLoading) {
        return null;
      }
      return test(userCtx) ? <Wrapped {...props} /> : <Redirect to={to} />;
    };
  };
}

export const redirectIfAuthed = redirectUnless(
  "/dashboard",
  ({ userUnauthed }) => userUnauthed
);

export const redirectIfUnauthed = redirectUnless(
  "/start",
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
