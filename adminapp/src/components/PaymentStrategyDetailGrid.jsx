import { dayjs } from "../modules/dayConfig";
import AdminLink from "./AdminLink";
import DetailGrid from "./DetailGrid";
import React from "react";

export default function PaymentStrategyDetailGrid({ adminDetails }) {
  return (
    <DetailGrid title="Strategy" anchorLeft properties={adminDetails.map(property)} />
  );
}

function property({ label, value, type }) {
  let typedValue, children;
  switch (type) {
    case "json":
      children = (
        <pre style={{ maxHeight: 250, overflow: "scroll" }}>
          {JSON.stringify(value, null, "  ")}
        </pre>
      );
      break;
    case "date":
      typedValue = dayjs(value);
      break;
    case "model":
      typedValue = <AdminLink to={value.link}>{value.label}</AdminLink>;
      break;
    case "href":
      typedValue = <AdminLink to={value}>{value}</AdminLink>;
      break;
    case "numeric":
    default:
      typedValue = value;
  }
  return { label, value: typedValue, children };
}
