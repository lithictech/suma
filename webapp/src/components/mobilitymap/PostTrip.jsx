import { t } from "../../localization";
import FormError from "../FormError";
import DrawerContents from "./DrawerContents";
import React from "react";
import Button from "react-bootstrap/Button";

export default function PostTrip({ endTrip, onCloseTrip, error }) {
  const { totalCost, discountAmount, provider } = endTrip;
  const handleClose = () => onCloseTrip();
  return (
    <DrawerContents>
      {t("mobility.trip_ended", {
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
        {t("common.close")}
      </Button>
    </DrawerContents>
  );
}
