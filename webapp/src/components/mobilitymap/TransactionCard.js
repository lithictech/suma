import FormError from "../FormError";
import i18next from "i18next";
import React from "react";
import { Button, Card } from "react-bootstrap";

const TransactionCard = ({ endTrip, onCloseTrip, error }) => {
  const { rate, provider, id } = endTrip;
  const { localizationVars: locVars } = rate;
  const handleClose = () => onCloseTrip();
  return (
    <Card className="cardContainer">
      <Card.Body>
        <p>
          Trip {id} with {provider.vendorName} has ended.
        </p>
        <p>
          {i18next.t(rate.localizationKey, {
            surchargeCents: locVars.surchargeCents * 0.01,
            unitCents: locVars.unitCents * 0.01,
            ns: "mobility",
          })}
        </p>
        <FormError error={error} />
        <Button size="sm" variant="secondary" className="w-100" onClick={handleClose}>
          Close
        </Button>
      </Card.Body>
    </Card>
  );
};

export default TransactionCard;
