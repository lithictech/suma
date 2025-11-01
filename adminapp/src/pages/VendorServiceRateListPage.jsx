import api from "../api";
import AdminLink from "../components/AdminLink";
import ResourceList from "../components/ResourceList";
import Money from "../shared/react/Money";
import React from "react";

export default function VendorServiceRateListPage() {
  return (
    <ResourceList
      resource="vendor_service_rate"
      apiList={api.getVendorServiceRates}
      canCreate
      columns={[
        {
          id: "id",
          label: "ID",
          align: "center",
          sortable: true,
          render: (c) => <AdminLink model={c} />,
        },
        {
          id: "name",
          label: "Name",
          align: "left",
          render: (c) => <AdminLink model={c}>{c.internalName}</AdminLink>,
        },
        {
          id: "unit",
          label: "Unit Amount",
          align: "center",
          render: (c) => <Money>{c.unitAmount}</Money>,
        },
        {
          id: "surcharge",
          label: "Surcharge",
          align: "center",
          render: (c) => <Money>{c.surcharge}</Money>,
        },
      ]}
    />
  );
}
