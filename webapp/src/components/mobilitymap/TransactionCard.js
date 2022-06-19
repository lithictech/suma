import FormError from "../FormError";
import CardOverlay from "./CardOverlay";
import i18next from "i18next";
import React from "react";
import Button from "react-bootstrap/Button";

const TransactionCard = ({ endTrip, onCloseTrip, error }) => {
  const { totalCost, discountAmount, provider } = endTrip;
  const handleClose = () => onCloseTrip();
  return (
    <CardOverlay>
      <p>
        {i18next.t("mobility:trip_ended", {
          vendor: provider.vendorName,
          totalCostCents: totalCost.cents * 0.01,
          discountAmountCents: discountAmount.cents * 0.01,
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
