import { md, t } from "../../localization";
import FormError from "../FormError";
import CardOverlay from "./CardOverlay";
import React from "react";
import Button from "react-bootstrap/Button";

const TransactionCard = ({ endTrip, onCloseTrip, error }) => {
  const { totalCost, discountAmount, provider } = endTrip;
  const handleClose = () => onCloseTrip();
  return (
    <CardOverlay>
      {md("mobility:trip_ended", {
        vendor: provider.vendorName,
        totalCost: totalCost,
        discountAmount: discountAmount,
      })}
      <FormError error={error} />
      <Button
        size="sm"
        variant="outline-secondary"
        className="w-100"
        onClick={handleClose}
      >
        {t("common:close")}
      </Button>
    </CardOverlay>
  );
};

export default TransactionCard;
