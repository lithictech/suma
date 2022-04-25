import loadingGif from "../../assets/images/loading.gif";
import FormError from "../FormError";
import i18next from "i18next";
import React from "react";
import Button from "react-bootstrap/Button";
import Card from "react-bootstrap/Card";

const ReservationCard = ({ active, loading, vehicle, onReserve, reserveError }) => {
  if (!active) {
    return null;
  }
  if (loading) {
    return (
      <Card className="reserve">
        <Card.Body>
          <img src={loadingGif} className="loading" alt="loading" />
        </Card.Body>
      </Card>
    );
  }
  const { rate, vendorService } = vehicle;
  const { localizationVars: locVars } = rate;
  const handlePress = (e) => {
    e.preventDefault();
    onReserve(vehicle);
  };

  return (
    <Card className="reserve">
      <Card.Body>
        {!reserveError ? (
          <>
            <Card.Title className="mb-2 text-muted">{vendorService.name}</Card.Title>
            <Card.Text className="text-muted">
              {i18next.t(rate.localizationKey, {
                surchargeCents: locVars.surchargeCents * 0.01,
                unitCents: locVars.unitCents * 0.01,
                ns: "mobility",
              })}
            </Card.Text>
            <Button size="sm" variant="success" onClick={handlePress}>
              Reserve Scooter
            </Button>
          </>
        ) : (
          <FormError error={reserveError} noMargin />
        )}
      </Card.Body>
    </Card>
  );
};

export default ReservationCard;
