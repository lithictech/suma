import { t } from "../localization";
import RLink from "./RLink";
import React from "react";
import Button from "react-bootstrap/Button";

export default function GoHome() {
  return (
    <div className="d-flex justify-content-center">
      <Button variant="primary" href="/dashboard" as={RLink}>
        {t("common:go_home")}
      </Button>
    </div>
  );
}
