import React from "react";
import Card from "react-bootstrap/Card";

const CardOverlay = ({ children }) => {
  return (
    <Card className="mobility-overlay-card">
      <Card.Body>{children}</Card.Body>
    </Card>
  );
};

export default CardOverlay;
