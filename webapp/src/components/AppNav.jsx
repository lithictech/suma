import { t } from "../localization";
import useGlobalViewState from "../state/useGlobalViewState";
import clsx from "clsx";
import React from "react";
import { Link, useLocation } from "react-router-dom";

export default function AppNav() {
  const { setAppNav } = useGlobalViewState();
  return (
    <div ref={setAppNav} className="app-nav d-flex flex-row">
      <AppLink to="/dashboard" label={t("titles.home")} className="border-end-0" />
      <AppLink to="/mobility" label={t("titles.mobility")} className="border-end-0" />
      <AppLink
        to="/food"
        label={t("food.title")}
        className="border-end-0"
        prefixes={["/checkout"]}
      />
      <AppLink to="/utilities" label={t("utilities.title")} />
    </div>
  );
}

const AppLink = ({ to, label, prefixes, className }) => {
  const location = useLocation();
  const active = [...(prefixes || []), to].some((x) => location.pathname.startsWith(x));
  return (
    <Link
      to={to}
      className={clsx(
        "btn btn-outline-primary app-link",
        active && "app-link-active",
        className
      )}
    >
      {label}
    </Link>
  );
};
