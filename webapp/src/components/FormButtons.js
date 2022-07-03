import { t } from "../localization";
import clsx from "clsx";
import React from "react";
import Button from "react-bootstrap/Button";
import Col from "react-bootstrap/Col";
import Row from "react-bootstrap/Row";

const FormButtons = ({ primaryProps, secondaryProps, variant, back, className }) => {
  if (back) {
    secondaryProps = {
      children: t("common:back"),
      onClick: () => window.history.back(),
    };
  }
  variant = variant || "outline-primary";
  return (
    <div className={clsx("mt-4 mx-4", className)}>
      <Row>
        <Col>
          {secondaryProps && (
            <Button variant="outline-secondary" className="w-100" {...secondaryProps} />
          )}
        </Col>
        <Col>
          {primaryProps && (
            <Button variant={variant} className="w-100" type="submit" {...primaryProps} />
          )}
        </Col>
      </Row>
    </div>
  );
};
export default FormButtons;
