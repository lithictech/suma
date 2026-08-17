import React from "react";
import { Navigate, NavigateProps } from "react-router-dom";

export default function Redirect({ to, ...rest }: NavigateProps) {
  return <Navigate replace to={to} {...rest} />;
}
