import api from "../api";
import AdminLink from "../components/AdminLink";
import RelatedList from "../components/RelatedList";
import ResourceDetail from "../components/ResourceDetail";
import { dayjs } from "../modules/dayConfig";
import React from "react";

export default function AnonMemberContactDetailPage() {
  return (
    <ResourceDetail
      resource="anon_member_contact"
      apiGet={api.getAnonMemberContact}
      apiDelete={api.destroyMemberContact}
      canEdit
      properties={(model) => [
        { label: "ID", value: model.id },
        { label: "Created At", value: dayjs(model.createdAt) },
        { label: "Phone", value: model.phone },
        { label: "Email", value: model.email },
        { label: "Relay", value: model.relayKey },
        {
          label: "Member",
          value: <AdminLink model={model.member}>{model.member.name}</AdminLink>,
        },
      ]}
    >
      {(model) => [
        <RelatedList
          title="Extenal Accounts"
          rows={model.vendorAccounts}
          headers={["Id", "Vendor"]}
          keyRowAttr="id"
          toCells={(row) => [
            <AdminLink model={row} />,
            <AdminLink model={row.configuration.vendor?.name}>
              {row.configuration.vendor?.name}
            </AdminLink>,
          ]}
        />,
      ]}
    </ResourceDetail>
  );
}
