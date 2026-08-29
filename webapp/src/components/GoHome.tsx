import { t } from "../localization";
import { RoutePath } from "../routing/RoutePath.ts";
import Button from "../ui/Button";
import React from "react";

interface GoHomeProps {
  to?: RoutePath;
  label?: React.ReactNode;
}

export default function GoHome({ to, label }: GoHomeProps) {
  return (
    <div className="button-stack mt-4">
      <Button variant="outline" to={to || "/dashboard"}>
        {label || t("common.go_home")}
      </Button>
    </div>
  );
}
