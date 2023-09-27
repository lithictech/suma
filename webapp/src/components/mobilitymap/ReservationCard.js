import { mdp, t } from "../../localization";
import FormError from "../FormError";
import PageLoader from "../PageLoader";
import RLink from "../RLink";
import SumaButton from "../SumaButton";
import CardOverlay from "./CardOverlay";
import LocationInstructionsAlert from "./LocationInstructionsAlert";
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
  const handleReserve = (e) => {
    e.preventDefault();
    onReserve(vehicle);
  };

  let action;
  if (vehicle.gotoPrivateAccount) {
    action = (
      <>
        {mdp("mobility:setup_private_account_with_vendor", {
          vendorName: vehicle.vendorService.vendorName,
        })}
        <Button
          size="sm"
          variant="outline-primary"
          className="w-100"
          href="/private-accounts"
          as={RLink}
        >
          {t("forms:get_started")}
        </Button>
      </>
    );
  } else if (vehicle.deeplink) {
    action = (
      <SumaButton variant="success" href={vehicle.deeplink}>
        {t("common:open_app")} <i className="ms-2 bi bi-box-arrow-up-right"></i>
      </SumaButton>
    );
  } else if (lastLocation) {
    action = (
      <SumaButton variant="success" onClick={handleReserve}>
        {t("mobility:reserve_scooter")}
      </SumaButton>
    );
  } else {
    action = <LocationInstructionsAlert />;
  }

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
      {action}
    </CardOverlay>
  );
};

export default ReservationCard;
