import { t } from "../localization";
import { RoutePath } from "../routing/RoutePath.ts";
import Button from "../ui/Button";
import React from "react";

interface GoHomeProps {
  href?: RoutePath;
  label?: React.ReactNode;
}

export default function GoHome({ href, label }: GoHomeProps) {
  return (
    <div className="button-stack mt-4">
      <Button variant="outline" href={href || "/dashboard"}>
        {label || t("common.go_home")}
      </Button>
    </div>
  );
}
