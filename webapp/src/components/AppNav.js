import clsx from "clsx";
import React from "react";
import { Link, useLocation } from "react-router-dom";

export default function AppNav() {
  return (
    <div className="d-flex flex-row">
      <AppLink to="/dashboard" label="Home" style={{ borderRightWidth: 0 }} />
      <AppLink to="/mobility" label="Mobility" style={{ borderRightWidth: 0 }} />
      <AppLink to="/food" label="Food" style={{ borderRightWidth: 0 }} />
      <AppLink to="/utilities" label="Utilities" />
    </div>
  );
}

const AppLink = ({ to, label, style }) => {
  const location = useLocation();
  return (
    <Link
      to={to}
      className={clsx(
        "btn btn-outline-primary app-link",
        location.pathname === to && "app-link-active"
      )}
      style={style}
    >
      {label}
    </Link>
  );
};
