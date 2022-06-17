import FormError from "../FormError";
import CardOverlay from "./CardOverlay";
import i18next from "i18next";
import React from "react";
import Button from "react-bootstrap/Button";

const TransactionCard = ({ endTrip, onCloseTrip, error }) => {
  const { rate, provider, id } = endTrip;
  const { localizationVars: locVars } = rate;
  const handleClose = () => onCloseTrip();
  return (
    <CardOverlay>
      <p>
        Trip {id} with {provider.vendorName} has ended.
      </p>
      <p>
        {i18next.t("mobility:" + rate.localizationKey, {
          surchargeCents: locVars.surchargeCents * 0.01,
          unitCents: locVars.unitCents * 0.01,
        })}
      </p>
      <FormError error={error} />
      <Button size="sm" variant="primary" className="w-100" onClick={handleClose}>
        {i18next.t("common:close")}
      </Button>
    </CardOverlay>
  );
};

export default TransactionCard;
