import api from "../../api";
import { t } from "../../localization";
import { dayjs } from "../../modules/dayConfig";
import useToggle from "../../shared/react/useToggle";
import { extractErrorCode, useError } from "../../state/useError";
import useUser from "../../state/useUser";
import FormButtons from "../FormButtons";
import FormError from "../FormError";
import DrawerContents from "./DrawerContents";
import DrawerLoading from "./DrawerLoading";
import DrawerTitle from "./DrawerTitle";
import PostTrip from "./PostTrip";
import React from "react";
import Button from "react-bootstrap/Button";
import Modal from "react-bootstrap/Modal";

export default function Trip({ trip, onCloseTrip, onEndTrip, lastLocation }) {
  const { handleUpdateCurrentMember } = useUser();
  const [endTrip, setEndTrip] = React.useState(null);
  const [error, setError] = useError();
  const showConfirm = useToggle(false);
  if (!endTrip && !lastLocation) {
    return <DrawerLoading />;
  }
  const handleEndTrip = () => {
    setError("");
    api
      .endMobilityTrip({
        lat: lastLocation.latlng.lat,
        lng: lastLocation.latlng.lng,
      })
      .tap(handleUpdateCurrentMember)
      .then((r) => {
        onEndTrip();
        setEndTrip(r.data);
      })
      .catch((e) => setError(extractErrorCode(e)));
  };
  // Ending a trip is a financial action, so confirm it first (WCAG 3.3.4).
  const handleConfirmEndTrip = (e) => {
    e.preventDefault();
    showConfirm.turnOff();
    handleEndTrip();
  };
  const handleCloseTrip = () => {
    onCloseTrip();
    setEndTrip(null);
  };
  return (
    <>
      {endTrip && (
        <PostTrip endTrip={endTrip} error={error} onCloseTrip={handleCloseTrip} />
      )}
      {trip && !endTrip && lastLocation && (
        <DrawerContents>
          <DrawerTitle>{trip.provider.name}</DrawerTitle>
          <p className="text-muted">
            {t("mobility.trip_started_at", {
              at: dayjs(trip.beganAt).format("LT"),
            })}
          </p>
          <FormError error={error} />
          <Button
            size="sm"
            variant="outline-danger"
            className="w-100"
            onClick={showConfirm.turnOn}
          >
            {t("mobility.end_trip")}
          </Button>
          <Modal show={showConfirm.isOn} onHide={showConfirm.turnOff} centered>
            <Modal.Header closeButton>
              <Modal.Title as="h5">{t("mobility.confirm_end_trip_title")}</Modal.Title>
            </Modal.Header>
            <Modal.Body>
              <p>{t("mobility.confirm_end_trip_body")}</p>
              <FormButtons
                variant="danger"
                primaryProps={{
                  children: t("mobility.end_trip"),
                  onClick: handleConfirmEndTrip,
                }}
                secondaryProps={{
                  children: t("common.cancel"),
                  onClick: showConfirm.turnOff,
                }}
              />
            </Modal.Body>
          </Modal>
        </DrawerContents>
      )}
    </>
  );
}
