import React from "react";
import { useUser } from "../state/useUser";
import Redirect from "../components/Redirect";

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
  "/sign-in",
  ({ userAuthed }) => userAuthed
);
