import RLink from "./RLink";
import clsx from "clsx";
import React from "react";
import Button from "react-bootstrap/Button";
import { useLocation } from "react-router-dom";

export default function AppNav() {
  return (
    <div className="d-flex flex-row">
      <AppLink to="/mobility" label="Mobility" style={{ borderRightWidth: 0 }} />
      <AppLink to="#todo" label="Food" style={{ borderRightWidth: 0 }} />
      <AppLink to="#todo" label="Utilities" />
    </div>
  );
}

const AppLink = ({ to, label, style }) => {
  const location = useLocation();
  return (
    <Button
      href={to}
      as={RLink}
      variant="outline-primary"
      className={clsx(
        "border-radius-0 flex-grow-1",
        location.pathname === to ? "active-outline-button" : "inactive-outline-button"
      )}
      style={style}
    >
      {label}
    </Button>
  );
};
