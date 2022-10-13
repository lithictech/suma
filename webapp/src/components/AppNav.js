import { t } from "../localization";
import clsx from "clsx";
import React from "react";
import { Link, useLocation } from "react-router-dom";

export default function AppNav() {
  return (
    <div className="app-nav d-flex flex-row sticky-top">
      <AppLink to="/dashboard" label={t("titles:home")} style={{ borderRightWidth: 0 }} />
      <AppLink
        to="/mobility"
        label={t("titles:mobility")}
        style={{ borderRightWidth: 0 }}
      />
      <AppLink to="/food" label={t("food:title")} style={{ borderRightWidth: 0 }} />
      <AppLink to="/utilities" label={t("utilities:title")} />
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
