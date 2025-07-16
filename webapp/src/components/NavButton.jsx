import { t } from "../localization";
import RLink from "./RLink";
import clsx from "clsx";
import React from "react";
import Button from "react-bootstrap/Button";

export default function NavButton({ left, right, className, children, ...rest }) {
  return (
    <Button
      size="sm"
      as={RLink}
      variant="link"
      className={clsx("p-0", className)}
      {...rest}
    >
      {left && <span className="me-1">{t("common.back_sym")}</span>}
      <span>{children}</span>
      {right && <span className="ms-1">{t("common.forward_sym")}</span>}
    </Button>
  );
}
