import formatDate from "../modules/formatDate";
import AdminLink from "./AdminLink";
import DetailGrid from "./DetailGrid";
import React from "react";

export default function CommerceOrderDetailGrid({ model }) {
  if (!model) {
    return null;
  }
  return (
    <DetailGrid
      title="Commerce Order"
      properties={[
        { label: "ID", value: <AdminLink model={model} /> },
        {
          label: "Created At",
          value: formatDate(model.createdAt),
        },
        { label: "Status", value: model.statusLabel },
      ]}
    />
  );
}
