import { mdp, t } from "../../localization";
import FormError from "../FormError";
import PageLoader from "../PageLoader";
import RLink from "../RLink";
import CardOverlay from "./CardOverlay";
import React from "react";
import Button from "react-bootstrap/Button";
import Card from "react-bootstrap/Card";

/**
 * Card that shows when you click a scooter on the map.
 *
 * @param active {boolean}
 * @param loading {boolean}
 * @param vehicle {{rate, vendorService}}
 * @param onReserve {function({rate, vendorService})} Called with the vehicle the user wants to return.
 * @param reserveError {*} Error returned if making the reservation fails.
 * @param canReserve {boolean} True if the vehicle can be reserved from the card.
 */
export default function ReservationCard({
  active,
  loading,
  vehicle,
  onReserve,
  reserveError,
}) {
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
      <Button size="sm" variant="success" className="w-100" href={vehicle.deeplink}>
        {t("common:open_app")} <i className="ms-2 bi bi-box-arrow-up-right"></i>
      </Button>
    );
  } else {
    action = (
      <Button size="sm" variant="success" className="w-100" onClick={handleReserve}>
        {t("mobility:reserve_scooter")}
      </Button>
    );
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
}
