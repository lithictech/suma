import { RoutePath } from "./RoutePath.ts";
import resolveRoutePath from "./resolveRoutePath.ts";
import React from "react";
import { Navigate, NavigateProps } from "react-router-dom";

interface RedirectProps extends Omit<NavigateProps, "to"> {
  to: RoutePath;
}

export default function Redirect({ to, ...rest }: RedirectProps) {
  return <Navigate replace to={resolveRoutePath(to)} {...rest} />;
}
