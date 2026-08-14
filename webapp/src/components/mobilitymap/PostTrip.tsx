import { t } from "../../localization";
import Button from "../../ui/Button";
import FormError from "../FormError";
import DrawerContents from "./DrawerContents";
import React from "react";

interface PostTripProps {
  endTrip: MobilityTrip;
  onCloseTrip: () => void;
  error?: any;
}

export default function PostTrip({ endTrip, onCloseTrip, error }: PostTripProps) {
  const { charge, provider } = endTrip;
  const handleClose = () => onCloseTrip();
  return (
    <DrawerContents>
      {t("mobility.trip_ended", {
        vendor: provider.vendorName,
        totalCost: charge.customerCost,
        discountAmount: charge.savings,
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
