import api from "../api";
import AdminLink from "../components/AdminLink";
import RelatedList from "../components/RelatedList";
import ResourceDetail from "../components/ResourceDetail";
import { dayjs } from "../modules/dayConfig";
import React from "react";

export default function OrganizationDetailPage() {
  return (
    <ResourceDetail
      resource="organization"
      apiGet={api.getOrganization}
      canEdit
      properties={(model) => [
        { label: "ID", value: model.id },
        { label: "Created At", value: dayjs(model.createdAt) },
        { label: "Updated At", value: dayjs(model.updatedAt) },
        { label: "Name", value: model.name },
      ]}
    >
      {(model) => (
        <>
          <RelatedList
            title={`Memberships (${model.memberships.length})`}
            rows={model.memberships}
            headers={["Id", "Member", "Created At", "Updated At"]}
            keyRowAttr="id"
            toCells={(row) => [
              row.id,
              <AdminLink key="member" model={row.member}>
                {row.member.name}
              </AdminLink>,
              dayjs(row.createdAt).format("lll"),
              dayjs(row.updatedAt).format("lll"),
            ]}
          />
        </>
      )}
    </ResourceDetail>
  );
}
