import { t } from "../localization";
import clsx from "clsx";
import React from "react";
import { Link } from "react-router-dom";

export default function LinearBreadcrumbs({ forward, back, noBottom }) {
  let Back, backProps;
  if (back === true) {
    Back = "a";
    backProps = { href: "#", onClick: () => window.history.back() };
  } else if (typeof back === "string") {
    Back = Link;
    backProps = { to: back };
  }
  return (
    <nav className={clsx(noBottom || "mb-3")}>
      <ol className="linear-breadcrumb m-0">
        {back && (
          <li>
            {t("common:back_sym")}
            <Back className="ms-1" {...backProps}>
              {t("common:back")}
            </Back>
          </li>
        )}
        {forward && (
          <li>
            <Link className="me-1" to={forward}>
              {t("common:next")}
            </Link>
            {t("common:next_sym")}
          </li>
        )}
      </ol>
    </nav>
  );
}
