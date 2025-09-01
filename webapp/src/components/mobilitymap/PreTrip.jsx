import { t } from "../../localization";
import FormError from "../FormError";
import RLink from "../RLink";
import DrawerContents from "./DrawerContents";
import DrawerLoading from "./DrawerLoading";
import DrawerTitle from "./DrawerTitle";
import React from "react";
import Button from "react-bootstrap/Button";

/**
 * Card that shows when you click a scooter on the map.
 *
 * @param loading {boolean}
 * @param vehicle {{rate, vendorService}}
 * @param onReserve {function({rate, vendorService})} Called with the vehicle the user wants to return.
 * @param reserveError {*} Error returned if making the reservation fails.
 */
export default function PreTrip({ loading, vehicle, onReserve, reserveError }) {
  if (loading) {
    return <DrawerLoading />;
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
        <p>
          {t("mobility.setup_private_account_with_vendor", {
            vendorName: vehicle.vendorService.vendorName,
          })}
        </p>
        <Button
          size="sm"
          variant="primary"
          className="w-100"
          href="/private-accounts"
          as={RLink}
        >
          {t("forms.get_started")}
        </Button>
      </>
    );
  } else if (vehicle.deeplink) {
    action = (
      <>
        <Button size="sm" variant="success" className="w-100" href={vehicle.deeplink}>
          {t("common.open_app")} <i className="ms-2 bi bi-box-arrow-up-right"></i>
        </Button>
        <div className="mt-2">
          {t("mobility.relink_private_account_with_vendor", {
            vendorName: vehicle.vendorService.vendorName,
          })}
        </div>
      </>
    );
  } else {
    action = (
      <Button size="sm" variant="success" className="w-100" onClick={handleReserve}>
        {t("mobility.reserve_scooter")}
      </Button>
    );
  }

  return (
    <DrawerContents>
      <DrawerTitle>{vendorService.name}</DrawerTitle>
      <p className="text-muted">
        {t(rate.localizationKey, {
          surchargeCents: {
            cents: locVars.surchargeCents,
            currency: locVars.surchargeCurrency,
          },
          unitCents: {
            cents: locVars.unitCents,
            currency: locVars.unitCurrency,
          },
        })}
      </p>
      <FormError error={reserveError} />
      {action}
    </DrawerContents>
  );
}
