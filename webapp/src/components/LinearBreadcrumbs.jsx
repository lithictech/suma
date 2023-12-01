import { t } from "../localization";
import clsx from "clsx";
import React from "react";
import Button from "react-bootstrap/Button";
import { Link } from "react-router-dom";

export default function LinearBreadcrumbs({ forward, back, noBottom }) {
  const Back = Button;
  let backProps;
  if (back === true) {
    backProps = { href: "#", onClick: () => window.history.back() };
  } else if (typeof back === "string") {
    backProps = { to: back, as: Link };
  }
  return (
    <nav className={clsx(noBottom || "mb-3")}>
      <ol className="linear-breadcrumb m-0">
        {back && (
          <li>
            <Back size="sm" {...backProps}>
              {t("common:back_sym")}
              <span className="ms-1">{t("common:back")}</span>
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
