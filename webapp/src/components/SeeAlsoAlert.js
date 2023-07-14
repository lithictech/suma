import RLink from "./RLink";
import clsx from "clsx";
import React from "react";
import Alert from "react-bootstrap/Alert";

export default function SeeAlsoAlert({
  label,
  iconClass,
  show,
  to,
  variant,
  textVariant,
}) {
  if (!show) {
    return null;
  }
  const linkCls = clsx(
    "stretched-link d-flex justify-content-between align-items-center text-decoration-none fw-bold",
    `text-${textVariant || variant}`
  );
  return (
    <Alert variant={variant} className="border-radius-0">
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
