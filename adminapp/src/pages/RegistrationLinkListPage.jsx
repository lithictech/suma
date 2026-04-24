import api from "../api";
import AdminLink from "../components/AdminLink";
import ResourceList from "../components/ResourceList";
import SafeExternalLink from "../shared/react/SafeExternalLink";
import React from "react";

export default function RegistrationLinkListPage() {
  return (
    <ResourceList
      resource="organization_registration_link"
      apiList={api.getOrganizationRegistrationLinks}
      canCreate
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
          id: "organization",
          label: "Organization",
          align: "left",
          sortable: true,
          render: (c) => <AdminLink model={c.organization} />,
        },
        {
          id: "durableUrl",
          label: "URL",
          align: "left",
          sortable: false,
          render: (c) => (
            <SafeExternalLink href={c.durableUrl}>{c.durableUrl}</SafeExternalLink>
          ),
        },
      ]}
    />
  );
}
