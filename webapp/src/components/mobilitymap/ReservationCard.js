import { t } from "../../localization";
import FormError from "../FormError";
import PageLoader from "../PageLoader";
import RLink from "../RLink";
import CardOverlay from "./CardOverlay";
import GeolocationInstructionsModal from "./GeolocationInstructionsModal";
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
        <p>To get started, we&rsquo;ll set up a private account for you in Lime.</p>
        <Button
          size="sm"
          variant="outline-primary"
          className="w-100"
          href="/private-accounts"
          as={RLink}
        >
          Get Started
        </Button>
      </>
    );
  } else if (vehicle.deeplink) {
    action = (
      <Button size="sm" variant="success" className="w-100" href={vehicle.deeplink}>
        Open App <i className="ms-2 bi bi-box-arrow-up-right"></i>
      </Button>
    );
  } else if (lastLocation) {
    action = (
      <Button size="sm" variant="success" className="w-100" onClick={handleReserve}>
        {t("mobility:reserve_scooter")}
      </Button>
    );
  } else {
    action = <GeolocationInstructionsModal />;
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
