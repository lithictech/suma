import api from "../api";
import AdminLink from "../components/AdminLink";
import ResourceList from "../components/ResourceList";
import { dayjs } from "../modules/dayConfig";
import dateFormat from "../shared/dateFormat";
import React from "react";

export default function MessageListPage() {
  return (
    <ResourceList
      resource="message_delivery"
      apiList={api.getMessageDeliveries}
      canSearch={false}
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
          render: (c) => dayjs(c.createdAt).format("lll"),
        },
        {
          id: "sent_at",
          label: "Sent",
          align: "left",
          sortable: true,
          render: (c) => dateFormat(c.sentAt, "lll"),
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
      ]}
    />
  );
}
