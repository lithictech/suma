import RLink from "./RLink";
import i18next from "i18next";
import React from "react";
import Button from "react-bootstrap/Button";

export default function GoHome() {
  return (
    <div className="d-flex justify-content-center">
      <Button variant="primary" href="/dashboard" as={RLink}>
        {i18next.t("common:go_home")}
      </Button>
    </div>
  );
}
