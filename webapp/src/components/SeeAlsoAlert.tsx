import Alert from "../ui/Alert";
import AlertLink from "../ui/AlertLink";
import clsx from "clsx";
import React from "react";

interface SeeAlsoAlertProps {
  label?: React.ReactNode;
  alertClass?: string;
  iconClass?: string;
  show?: boolean;
  to?: string;
  variant?: string;
}

export default function SeeAlsoAlert({
  label,
  alertClass,
  iconClass,
  show,
  to,
  variant,
}: SeeAlsoAlertProps) {
  if (!show) {
    return null;
  }
  const linkCls = clsx(
    "stretched-link d-flex justify-content-between align-items-centerl"
  );
  return (
    <Alert variant={variant} className={clsx("border-radius-0", alertClass)}>
      <AlertLink href={to} className={linkCls}>
        <i className={`bi ${iconClass} me-3`}></i>
        {label}
        <div className="ms-auto">
          <i className="bi bi-arrow-right-circle-fill ms-1"></i>
        </div>
      </AlertLink>
    </Alert>
  );
}
