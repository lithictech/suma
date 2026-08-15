import { t } from "../localization";
import Button from "../ui/Button";
import RLink from "./RLink";
import React from "react";

interface GoHomeProps {
  href?: string;
  label?: React.ReactNode;
}

export default function GoHome({ href, label }: GoHomeProps) {
  return (
    <div className="button-stack mt-4">
      <Button variant="outline" href={href || "/dashboard"} as={RLink}>
        {label || t("common.go_home")}
      </Button>
    </div>
  );
}
