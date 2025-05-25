import api from "../api";
import AdminLink from "../components/AdminLink";
import ResourceList from "../components/ResourceList";
import formatDate from "../modules/formatDate";
import React from "react";

export default function MessageListPage() {
  return (
    <ResourceList
      resource="message_delivery"
      apiList={api.getMessageDeliveries}
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
          id: "created_at",
          label: "Created",
          align: "left",
          sortable: true,
          render: (c) => formatDate(c.createdAt),
        },
        {
          id: "sent_at",
          label: "Sent",
          align: "left",
          sortable: true,
          render: (c) => formatDate(c.sentAt),
        },
        {
          id: "to",
          label: "To",
          align: "left",
          render: (c) =>
            c.recipient ? (
              <AdminLink model={c.recipient}>{c.recipient.name}</AdminLink>
            ) : (
              c.to
            ),
        },
        {
          id: "template",
          label: "Template",
          align: "left",
          render: (c) => c.template,
        },
      ]}
    />
  );
}
