import api from "../api";
import AdminLink from "../components/AdminLink";
import RelatedList from "../components/RelatedList";
import ResourceDetail from "../components/ResourceDetail";
import { dayjs } from "../modules/dayConfig";
import formatDate from "../modules/formatDate";
import React from "react";

export default function MarketingListDetailPage() {
  return (
    <ResourceDetail
      resource="marketing_list"
      apiGet={api.getMarketingList}
      properties={(model, replaceModel) => [
        { label: "ID", value: model.id },
        { label: "Created At", value: dayjs(model.createdAt) },
        {
          label: "Label",
          value: model.label,
        },
        {
          label: "Managed",
          value: model.managed,
        },
      ]}
    >
      {(model) => [
        <RelatedList
          title="Members"
          rows={model.members}
          headers={["Id", "Name", "Phone"]}
          keyRowAttr="id"
          toCells={(row) => [
            <AdminLink key="id" model={row} />,
            <AdminLink key="name" model={row}>
              {row.name}
            </AdminLink>,
            row.phone,
          ]}
        />,
        <RelatedList
          title="Broadcasts"
          rows={model.smsBroadcasts}
          headers={["Id", "Label", "Sent At"]}
          keyRowAttr="id"
          toCells={(row) => [
            <AdminLink key="id" model={row} />,
            <AdminLink key="label" model={row}>
              {row.label}
            </AdminLink>,
            formatDate(row.sentAt),
          ]}
        />,
      ]}
    </ResourceDetail>
  );
}
