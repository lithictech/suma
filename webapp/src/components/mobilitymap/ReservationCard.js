import loadingGif from "../../assets/images/loading.gif";
import FormError from "../FormError";
import React from "react";
import Button from "react-bootstrap/Button";
import Card from "react-bootstrap/Card";

const ReservationCard = ({ active, loading, vehicle, onReserve, reserveError }) => {
  // const { t } = useTranslation();
  if (!active) {
    return null;
  }
  if (loading) {
    return (
      <Card className="reserve">
        <Card.Body>
          <img src={loadingGif} className="loading" />
        </Card.Body>
      </Card>
    );
  }
  const { rate, vendorService } = vehicle;
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
              {rate.name}
              {/*{t("scooter_cost", {*/}
              {/*  startCost: ride.startCost,*/}
              {/*  costPerMinute: ride.costPerMinute,*/}
              {/*})}*/}
            </Card.Text>
            <Button size="sm" variant="success" onClick={handlePress}>
              Reserve Scooter
            </Button>
          </>
        ) : (
          <FormError error={reserveError} noPadding />
        )}
      </Card.Body>
    </Card>
  );
};

export default ReservationCard;
