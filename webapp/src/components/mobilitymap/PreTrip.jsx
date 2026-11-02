import { t } from "../../localization";
import FormError from "../FormError";
import RLink from "../RLink";
import DrawerContents from "./DrawerContents";
import DrawerLoading from "./DrawerLoading";
import DrawerTitle from "./DrawerTitle";
import MicromobilityRate from "./MicromobilityRate.jsx";
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
  const handleReserve = (e) => {
    e.preventDefault();
    onReserve(vehicle);
  };

  let action;
  if (vehicle.usageProhibitedReason) {
    action = <p className="mb-0">{t(vehicle.usageProhibitedReason)}</p>;
  } else if (vehicle.gotoPrivateAccount) {
    action = (
      <>
        <p className="mb-0">
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
        <hr className="my-0" />
        <Button
          className="p-1 ps-0 align-self-start"
          variant="link"
          href={vehicle.deeplink}
        >
          {t("mobility.open_app_ride", { vendorName: vehicle.vendorService.vendorName })}{" "}
          <i className="ms-2 bi bi-box-arrow-right"></i>
        </Button>
        <div>
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
      <DrawerTitle>{vehicle.vendorService.name}</DrawerTitle>
      <MicromobilityRate rate={vehicle.rate} />
      <FormError error={reserveError} />
      {action}
    </DrawerContents>
  );
}
