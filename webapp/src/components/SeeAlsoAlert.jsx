import RLink from "./RLink";
import clsx from "clsx";
import React from "react";
import Alert from "react-bootstrap/Alert";

export default function SeeAlsoAlert({
  label,
  alertClass,
  iconClass,
  show,
  to,
  variant,
}) {
  if (!show) {
    return null;
  }
  const linkCls = clsx(
    "stretched-link d-flex justify-content-between align-items-centerl"
  );
  return (
    <Alert variant={variant} className={clsx("border-radius-0", alertClass)}>
      <Alert.Link as={RLink} href={to} className={linkCls}>
        <i className={`bi ${iconClass} me-3`}></i>
        {label}
        <div className="ms-auto">
          <i className="bi bi-arrow-right-circle-fill ms-1"></i>
        </div>
      </Alert.Link>
    </Alert>
  );
}
