import api from "../api";
import AdminLink from "../components/AdminLink";
import ResourceList from "../components/ResourceList";
import { dayjs } from "../modules/dayConfig";
import React from "react";

export default function PaymentTriggerListPage() {
  return (
    <ResourceList
      resource="payment_trigger"
      toCreate="/payment-trigger/new"
      apiList={api.getPaymentTriggers}
      canSearch
      columns={[
        {
          id: "id",
          label: "ID",
          align: "center",
          sortable: true,
          render: (c) => <AdminLink model={c} />,
        },
        {
          id: "label",
          label: "Label",
          sortable: true,
          render: (c) => <AdminLink model={c}>{c.label}</AdminLink>,
        },
        {
          id: "active_during",
          label: "Active During",
          sortable: true,
          render: (c) =>
            `${dayjs(c.activeDuringBegin).format("ll")} - ${dayjs(
              c.activeDuringEnd
            ).format("ll")}`,
        },
      ]}
    />
  );
}
