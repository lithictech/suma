import React from "react";
import Button from "react-bootstrap/Button";
import Card from "react-bootstrap/Card";
import { useTranslation } from "react-i18next";

const ReservationCard = () => {
  const { t } = useTranslation();
  const ride = {
    number: 3434,
    startCost: 3.0,
    costPerMinute: 0.22,
  };
  return (
    <Card className="reserve">
      <Card.Body>
        <Card.Title className="mb-2 text-muted">Scooter {ride.number}</Card.Title>
        <Card.Text className="text-muted">
          {t("scooter_cost", {
            startCost: ride.startCost,
            costPerMinute: ride.costPerMinute,
          })}
        </Card.Text>
        <Button
          size="sm"
          variant="outline-success"
          href="http://google.com"
          onClick={(e) => e.preventDefault()}
        >
          Reserve Scooter
        </Button>
      </Card.Body>
    </Card>
  );
};

export default ReservationCard;
