import { t } from "../../localization";
import useToggle from "../../shared/react/useToggle";
import FormButtons from "../FormButtons";
import FormError from "../FormError";
import RLink from "../RLink";
import DrawerContents from "./DrawerContents";
import DrawerLoading from "./DrawerLoading";
import DrawerTitle from "./DrawerTitle";
import MicromobilityRate from "./MicromobilityRate.jsx";
import React from "react";
import Button from "react-bootstrap/Button";
import Modal from "react-bootstrap/Modal";

/**
 * Card that shows when you click a scooter on the map.
 *
 * @param loading {boolean}
 * @param vehicle {{rate, vendorService}}
 * @param onReserve {function({rate, vendorService})} Called with the vehicle the user wants to return.
 * @param reserveError {*} Error returned if making the reservation fails.
 */
export default function PreTrip({ loading, vehicle, onReserve, reserveError }) {
  const showConfirm = useToggle(false);
  if (loading) {
    return <DrawerLoading />;
  }
  // Reserving begins a paid trip (unlock fee plus per-minute rate),
  // so confirm before charging (WCAG 3.3.4).
  const handleReserve = (e) => {
    e.preventDefault();
    showConfirm.turnOff();
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
      <>
        <Button
          size="sm"
          variant="success"
          className="w-100"
          onClick={showConfirm.turnOn}
        >
          {t("mobility.reserve_scooter")}
        </Button>
        <Modal show={showConfirm.isOn} onHide={showConfirm.turnOff} centered>
          <Modal.Header closeButton>
            <Modal.Title as="h5">{t("mobility.confirm_reserve_title")}</Modal.Title>
          </Modal.Header>
          <Modal.Body>
            <p>{t("mobility.confirm_reserve_body")}</p>
            <MicromobilityRate rate={vehicle.rate} />
            <FormButtons
              variant="success"
              primaryProps={{
                children: t("mobility.reserve_scooter"),
                onClick: handleReserve,
              }}
              secondaryProps={{
                children: t("common.cancel"),
                onClick: showConfirm.turnOff,
              }}
            />
          </Modal.Body>
        </Modal>
      </>
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
