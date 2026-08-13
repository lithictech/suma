import { t } from "../localization";
import Button from "../ui/Button";
import RLink from "./RLink";
import React from "react";

export default function GoHome({ href, label }) {
  return (
    <div className="button-stack mt-4">
      <Button variant="outline-primary" href={href || "/dashboard"} as={RLink}>
        {label || t("common.go_home")}
      </Button>
    </div>
  );
}
