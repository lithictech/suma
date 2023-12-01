import { t } from "../localization";
import NavButton from "./NavButton";
import clsx from "clsx";
import React from "react";

export default function LinearBreadcrumbs({ back, noBottom }) {
  let backProps;
  if (back === true) {
    backProps = {
      to: "#",
      onClick: (e) => {
        e.preventDefault();
        window.history.back();
      },
    };
  } else if (typeof back === "string") {
    backProps = { to: back };
  }
  return (
    <nav className={clsx(noBottom || "mb-1")}>
      <ol className="linear-breadcrumb m-0">
        {back && (
          <li>
            <NavButton left size="sm" {...backProps}>
              {t("common:back")}
            </NavButton>
          </li>
        )}
      </ol>
    </nav>
  );
}
