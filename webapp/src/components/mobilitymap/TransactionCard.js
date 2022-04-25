import FormError from "../FormError";
import i18next from "i18next";
import React from "react";
import { Button, Card } from "react-bootstrap";

const TransactionCard = ({ endTrip, onCloseTrip, error }) => {
  const { rate, provider, id } = endTrip;
  const { localizationVars: locVars } = rate;
  const handleClose = () => onCloseTrip();
  return (
    <Card className="reserve">
      <Card.Body>
        {/* TODO: localization */}
        <p>Your trip {id} has ended.</p>
        <p>Provider: {provider.vendorName}</p>
        <p>
          Rate:
          {i18next.t(rate.localizationKey, {
            surchargeCents: locVars.surchargeCents * 0.01,
            unitCents: locVars.unitCents * 0.01,
            ns: "mobility",
          })}
        </p>
        <p>Total: $2</p>
        <FormError error={error} />
        <Button size="sm" variant="outline-success" onClick={handleClose}>
          Done
        </Button>
      </Card.Body>
    </Card>
  );
};

export default TransactionCard;
