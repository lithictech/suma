import { t } from "../../localization";
import FormError from "../FormError";
import PageLoader from "../PageLoader";
import CardOverlay from "./CardOverlay";
import InstructionsModal from "./InstructionsModal";
import React from "react";
import Button from "react-bootstrap/Button";
import Card from "react-bootstrap/Card";

const ReservationCard = ({
  active,
  loading,
  vehicle,
  onReserve,
  reserveError,
  lastLocation,
}) => {
  if (!active) {
    return null;
  }
  if (loading) {
    return (
      <CardOverlay>
        <PageLoader relative />
      </CardOverlay>
    );
  }
  const { rate, vendorService } = vehicle;
  const { localizationVars: locVars } = rate;
  const handlePress = (e) => {
    e.preventDefault();
    onReserve(vehicle);
  };

  return (
    <CardOverlay>
      <Card.Title className="mb-2">{vendorService.name}</Card.Title>
      <Card.Text className="text-muted">
        {t("mobility:" + rate.localizationKey, {
          surchargeCents: {
            cents: locVars.surchargeCents,
            currency: locVars.surchargeCurrency,
          },
          unitCents: {
            cents: locVars.unitCents,
            currency: locVars.unitCurrency,
          },
        })}
      </Card.Text>
      <FormError error={reserveError} />
      {lastLocation ? (
        <Button
          size="sm"
          variant="outline-success"
          className="w-100"
          onClick={handlePress}
        >
          {t("mobility:reserve_scooter")}
        </Button>
      ) : (
        <InstructionsModal />
      )}
    </CardOverlay>
  );
};

export default ReservationCard;
