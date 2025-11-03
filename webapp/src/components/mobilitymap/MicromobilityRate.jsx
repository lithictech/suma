import { t } from "../../localization/index.jsx";
import React from "react";
import Badge from "react-bootstrap/Badge";

export default function MicromobilityRate({ rate }) {
  let disc,
    badge = null;
  if (rate.undiscountedRate) {
    disc = (
      <p className="mb-0">
        <strike>
          {t("mobility.rate_micromobility", {
            surcharge: rate.undiscountedRate.surcharge,
            unitAmount: rate.undiscountedRate.unitAmount,
          })}
        </strike>
      </p>
    );
    badge = (
      <Badge bg="success" className="ms-2">
        {rate.name}
      </Badge>
    );
  }
  return (
    <div className="d-flex flex-column gap-2">
      {disc}
      <p className="mb-0">
        {t("mobility.rate_micromobility", {
          surcharge: rate.surcharge,
          unitAmount: rate.unitAmount,
        })}
        {badge}
      </p>
    </div>
  );
}
