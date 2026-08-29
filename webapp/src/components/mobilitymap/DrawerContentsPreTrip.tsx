import { t } from "../../localization";
import { untypedRoutePath } from "../../routing/RoutePath.ts";
import Button from "../../ui/Button";
import FormError from "../../ui/FormError";
import DrawerContents from "./DrawerContents";
import DrawerContentsLoading from "./DrawerContentsLoading.tsx";
import DrawerTitle from "./DrawerTitle";
import MicromobilityRate from "./MicromobilityRate";
import React from "react";

interface PreTripProps {
  loading?: boolean;
  vehicle: MobilityDetailedVehicle;
  onReserve: (vehicle: MobilityDetailedVehicle) => void;
  reserveError?: any;
}

/**
 * Card that shows when you click a scooter on the map.
 */
export default function DrawerContentsPreTrip({
  loading,
  vehicle,
  onReserve,
  reserveError,
}: PreTripProps) {
  if (loading) {
    return <DrawerContentsLoading />;
  }
  const handleReserve = (e: React.MouseEvent) => {
    e.preventDefault();
    onReserve(vehicle);
  };

  let action: React.ReactNode;
  if (vehicle.usageProhibitedReason) {
    action = <FormError error={vehicle.usageProhibitedReason} noSurface />;
  } else if (vehicle.gotoPrivateAccount) {
    action = (
      <>
        <p className="mb-0">
          {t("mobility.setup_private_account_with_vendor", {
            vendorName: vehicle.vendorService.vendorName,
          })}
        </p>
        <Button size="sm" variant="primary" className="w-100" to="/private-accounts">
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
          variant="text"
          to={untypedRoutePath(vehicle.deeplink)}
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
      <Button size="sm" variant="primary" className="w-100" onClick={handleReserve}>
        {t("mobility.reserve_scooter")}
      </Button>
    );
  }

  let matchDiv: React.ReactNode;
  if (vehicle?.subsidyMatchPercentage > 0) {
    matchDiv = (
      <div>
        {t("mobility.rate_additional_savings", {
          percentage: vehicle.subsidyMatchPercentage,
        })}
      </div>
    );
  }

  return (
    <DrawerContents>
      <DrawerTitle>{vehicle.vendorService.name}</DrawerTitle>
      <MicromobilityRate rate={vehicle.rate} />
      <FormError error={reserveError} />
      {action}
      {matchDiv}
    </DrawerContents>
  );
}
