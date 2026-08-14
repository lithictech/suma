import { t } from "../localization";
import RLink from "./RLink";
import React from "react";
import Button from "react-bootstrap/Button";

interface GoHomeProps {
  href?: string;
  label?: React.ReactNode;
}

export default function GoHome({ href, label }: GoHomeProps) {
  return (
    <div className="button-stack mt-4">
      <Button variant="outline-primary" href={href || "/dashboard"} as={RLink}>
        {label || t("common.go_home")}
      </Button>
    </div>
  );
}
